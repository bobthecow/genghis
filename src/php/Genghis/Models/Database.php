<?php

class Genghis_Models_Database implements ArrayAccess, Genghis_JsonEncodable
{
    public $name;
    public $server;
    public $database;

    private $collections = array();
    private $mongoCollections;

    public function __construct(Genghis_Models_Server $server, MongoDB $database)
    {
        $this->server   = $server;
        $this->database = $database;
        $this->name     = (string) $database;
    }

    public function drop()
    {
        $this->database->drop();
    }

    public function offsetExists($name)
    {
        return ($this->getMongoCollection($name) !== null);
    }

    public function offsetGet($name)
    {
        if (!isset($this->collections[$name])) {
            $coll = $this->getMongoCollection($name);

            if ($coll === null) {
                throw new Genghis_HttpException(404, sprintf("Collection '%s' not found in '%s'", $name, $this->name));
            }

            $this->collections[$name] = new Genghis_Models_Collection($this, $coll);
        }

        return $this->collections[$name];
    }

    public function offsetSet($name, $value)
    {
        throw new Exception;
    }

    public function offsetUnset($name)
    {
        $this[$name]->drop();
    }

    public function getCollectionNames()
    {
        $colls = array();
        foreach ($this->getMongoCollections() as $coll) {
            $colls[] = $coll->getName();
        }

        return $colls;
    }

    public function listCollections()
    {
        return array_map(array($this, 'offsetGet'), $this->getCollectionNames());
    }

    public function createCollection($name)
    {
        if (isset($this[$name])) {
            throw new Genghis_HttpException(400, sprintf("Collection '%s' already exists in '%s'", $name, $this->name));
        }

        try {
            $this->database->createCollection($name);
        } catch (Exception $e) {
            if (strpos($e->getMessage(), 'invalid name') !== false) {
                throw new Genghis_HttpException(400, 'Invalid collection name');
            }
            throw $e;
        }

        unset($this->mongoCollections);

        return $this[$name];
    }

    public function asJson()
    {
        $dbs = $this->server->getConnection()->listDBs();
        foreach ($dbs['databases'] as $db) {
            if ($db['name'] == $this->name) {
                $colls = $this->getCollectionNames();

                return array(
                    'id'          => $db['name'],
                    'name'        => $db['name'],
                    'count'       => count($colls),
                    'collections' => $colls,
                    'size'        => $db['sizeOnDisk'],
                );
            }
        }

        throw new Genghis_HttpException(404, sprintf("Database '%s' not found on '%s'", $database, $server));
    }

    private function getMongoCollection($name)
    {
        foreach ($this->getMongoCollections() as $coll) {
            if ($coll->getName() === $name) {
                return $coll;
            }
        }
    }

    private function getMongoCollections()
    {
        if (!isset($this->mongoCollections)) {
            $this->mongoCollections = $this->database->listCollections();
        }

        return $this->mongoCollections;
    }
}
