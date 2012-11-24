<?php

class Genghis_Models_Server implements ArrayAccess, Genghis_JsonEncodable
{
    public $dsn;
    public $name;
    public $options;
    public $default;
    public $db;

    private $connection;
    private $databases = array();

    public function __construct($dsn, $default = false)
    {
        $this->default = $default;

        try {
            $config = self::parseDsn($dsn);
            $this->name    = $config['name'];
            $this->dsn     = $config['dsn'];
            $this->options = $config['options'];

            if (isset($config['db'])) {
                $this->db = $config['db'];
            }
        } catch (Genghis_HttpException $e) {
            $this->name  = $dsn;
            $this->dsn   = $dsn;
            $this->error = $e->getMessage();
        }
    }

    public function offsetExists($name)
    {
        $list = $this->listDBs();
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
            $this->connection = new Mongo($this->dsn, array_merge(array('timeout' => 1000), $this->options));
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
        $list = $this->listDBs();
        foreach ($list['databases'] as $db) {
            $dbs[] = $this[$db['name']];
        }

        return $dbs;
    }

    public function getDatabaseNames()
    {
        $names = array();
        $list = $this->listDBs();
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
            $res = $this->listDBs();

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

    const DSN_PATTERN = "~^(?:mongodb://)?(?:(?P<username>[^:@]+):(?P<password>[^@]+)@)?(?P<host>[^,/@:]+)(?::(?P<port>\d+))?(?:/(?P<database>[^\?]+)?(?:\?(?P<options>.*))?)?$~";

    public static function parseDsn($dsn)
    {
        $chunks = array();
        if (!preg_match(self::DSN_PATTERN, $dsn, $chunks)) {
            throw new Genghis_HttpException(400, 'Malformed server DSN');
        }

        if (strpos($dsn, 'mongodb://') !== 0) {
            $dsn = 'mongodb://'.$dsn;
        }

        $options = array();
        if (isset($chunks['options'])) {
            parse_str($chunks['options'], str_replace(';', '&', $options));
            foreach ($options as $name => $value) {
                switch ($name) {
                    case 'replicaSet':
                        $options['replicaSet'] = (string) $value;
                        break;

                    case 'connectTimeoutMS':
                        $options['timeout'] = intval($value);
                        break;

                    case 'slaveOk':
                    case 'safe':
                    case 'w':
                    case 'wtimeoutMS':
                    case 'fsync':
                    case 'journal':
                    case 'socketTimeoutMS':
                        throw new Genghis_HttpException(400, 'Unsupported connection option - ' . $name);

                    default:
                        throw new Genghis_HttpException(400, 'Malformed server DSN: Unknown connection option - ' . $name);
                }
            }
        }

        $name = $chunks['host'];
        if (isset($chunks['username']) && !empty($chunks['username'])) {
            $name = $chunks['username'].'@'.$name;
        }
        if (isset($chunks['port']) && !empty($chunks['port'])) {
            $port = intval($chunks['port']);
            if ($port !== 27017) {
                $name .= ':'.$port;
            }
        }
        if (isset($chunks['database']) && !empty($chunks['database']) && $chunks['database'] != 'admin') {
            $db   = $chunks['database'];
            $name .= '/'.$db;
        }

        $ret = compact('name', 'dsn', 'options');

        if (isset($db)) {
            $ret['db'] = $db;
        }

        return $ret;
    }

    private function listDbs()
    {
        // Fake it if we've got a single-db connection.
        if (isset($this->db)) {
            $stats = $this->getConnection()
                ->selectDB($this->db)
                ->command(array('dbStats' => true));

            return array(
                'totalSize' => $stats['fileSize'],
                'databases' => array(array('name' => $this->db)),
            );
        }

        return $this->getConnection()->listDBs();
    }
}
