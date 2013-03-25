<?php

class Genghis_Models_Database implements ArrayAccess, Genghis_JsonEncodable
{
    public $name;
    public $server;
    public $database;
    public $error;

    private $collections = array();
    private $mongoCollections;

    public function __construct(Genghis_Models_Server $server, $name)
    {
        $this->server = $server;
        $this->name   = $name;
    }

    public function drop()
    {
        $this->getDatabase()->drop();
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
            $this->getDatabase()->createCollection($name);
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
        try {
            // Since we're lazily loading our DB, check for connection errors.
            $db = $this->getDatabase();
        } catch (Exception $e) {
            return array(
                'id'          => $this->name,
                'name'        => $this->name,
                'error'       => $this->cleanError($e->getMessage()),
            );
        }

        $colls = $this->getCollectionNames();

        return array(
            'id'          => $this->name,
            'name'        => $this->name,
            'count'       => count($colls),
            'collections' => $colls,
            'stats'       => $this->stats(),
        );
    }

    private function getDatabase()
    {
        if (!isset($this->database)) {
            $this->database = $this->server->getConnection()->selectDB($this->name);
        }

        return $this->database;
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
            $this->mongoCollections = $this->getDatabase()->listCollections();
        }

        return $this->mongoCollections;
    }

    private function stats()
    {
        return $this->getDatabase()->command(array('dbStats' => 1));
    }

    private function cleanError($msg)
    {
        return ucfirst(preg_replace('/^MongoDB::__construct\(\): /', '', $msg));
    }
}
