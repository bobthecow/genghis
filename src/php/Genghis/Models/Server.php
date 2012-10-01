<?php

class Genghis_Models_Server implements ArrayAccess, Genghis_JsonEncodable
{
    public $dsn;
    public $name;
    public $options;
    public $default;

    private $connection;
    private $databases = array();

    public function __construct($dsn, $default = false)
    {
        $this->default = $default;

        try {
            $config = self::parseDsn($dsn);

            $this->name       = $config['name'];
            $this->dsn        = $config['dsn'];
            $this->options    = $config['options'];
        } catch (Genghis_HttpException $e) {
            $this->name  = $dsn;
            $this->dsn   = $dsn;
            $this->error = $e->getMessage();
        }
    }

    public function offsetExists($name)
    {
        $list = $this->getConnection()->listDBs();

        foreach ($list['databases'] as $db) {
            if ($db['name'] === $name) {
                return true;
            }
        }

        return false;
    }

    public function offsetGet($name)
    {
        if (!isset($this[$name])) {
            throw new Genghis_HttpException(404, sprintf("Database '%s' not found on '%s'", $name, $this->name));
        }

        if (!isset($this->databases[$name])) {
            $this->databases[$name] = new Genghis_Models_Database($this, $this->getConnection()->selectDB($name));
        }

        return $this->databases[$name];
    }

    public function getConnection()
    {
        if (!isset($this->connection)) {
            $this->connection = new Mongo($this->dsn, $this->options);
        }

        return $this->connection;
    }

    public function createDatabase($name)
    {
        if (isset($this[$name])) {
            throw new Genghis_HttpException(400, sprintf("Database '%s' already exists on '%s'", $name, $this->name));
        }

        try {
            $db = $this->connection->selectDB($name);
        } catch (Exception $e) {
            if (strpos($e->getMessage(), 'invalid name') !== false) {
                throw new Genghis_HttpException(400, 'Invalid database name');
            }
            throw $e;
        }

        $db->selectCollection('__genghis_tmp_collection__')->drop();

        return $this[$name];
    }

    public function listDatabases()
    {
        $dbs = array();
        $list = $this->getConnection()->listDBs();
        foreach ($list['databases'] as $db) {
            $dbs[] = $this[$db['name']];
        }

        return $dbs;
    }

    public function getDatabaseNames()
    {
        $names = array();
        $list = $this->getConnection()->listDBs();
        foreach ($list['databases'] as $db) {
            $names[] = $db['name'];
        }

        return $names;
    }

    public function offsetSet($name, $value)
    {
        throw new Exception;
    }

    public function offsetUnset($name)
    {
        $this[$name]->drop();
    }

    public function asJson()
    {
        $server = array(
            'id'       => $this->name,
            'name'     => $this->name,
            'editable' => !$this->default,
        );

        if (isset($this->error)) {
            $server['error'] = $this->error;

            return $server;
        }

        try {
            $res = $this->getConnection()->listDBs();

            if (isset($res['errmsg'])) {
                $server['error'] = sprintf("Unable to connect to Mongo server at '%s': %s", $this->name, $res['errmsg']);

                return $server;
            }

            $dbs = $this->getDatabaseNames();

            return array_merge($server, array(
                'size'      => $res['totalSize'],
                'count'     => count($dbs),
                'databases' => $dbs,
            ));
        } catch (Exception $e) {
            $server['error'] = sprintf("Unable to connect to Mongo server at '%s'", $this->name);

            return $server;
        }
    }

    public static function parseDsn($dsn)
    {
        if (strpos($dsn, '://') === false) {
            $dsn = 'mongodb://'.$dsn;
        } else if (strpos($dsn, 'mongodb://') !== 0) {
            throw new Genghis_HttpException(400, 'Malformed server DSN: unknown URI scheme');
        }

        $chunks = parse_url($dsn);
        if ($chunks === false || isset($chunks['query']) || isset($chunks['fragment']) || !isset($chunks['host'])) {
            throw new Genghis_HttpException(400, 'Malformed server DSN');
        }

        $options = array();
        if (isset($chunks['query'])) {
            parse_str($chunks['query'], $options);
            foreach ($options as $name => $value) {
                if (!in_array($name, array('replicaSet'))) {
                    throw new Genghis_HttpException(400, 'Malformed server DSN: Unknown option — ' . $name);
                }

                $options[$name] = (string) $value;
            }
        }

        $name = $chunks['host'];
        if (isset($chunks['user'])) {
            $name = $chunks['user'].'@'.$name;
        }
        if (isset($chunks['port']) && $chunks['port'] !== 27017) {
            $name .= ':'.$chunks['port'];
        }

        return compact('name', 'dsn', 'options');
    }
}
