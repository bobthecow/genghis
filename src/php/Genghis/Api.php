<?php

class Genghis_Api extends Genghis_App
{
    // api/servers/:serverName/databases/:databaseName/collections/:collectionName/documents/:documentId
    const ROUTE_PATTERN = '~^/?servers(?:/(?P<server>[^/]+)(?P<databases>/databases(?:/(?P<database>[^/]+)(?P<collections>/collections(?:/(?P<collection>[^/]+)(?P<documents>/documents(?:/(?P<document>[^/]+))?)?)?)?)?)?)?/?$~';

    const CHECK_STATUS_ROUTE = '~/?check-status/?$~';

    const PAGE_LIMIT = 50;

    protected $servers;

    public function run()
    {
        try {
            return parent::run();
        } catch (Genghis_HttpException $e) {
            $msg = $e->getMessage() ? $e->getMessage() : Genghis_Response::getStatusText($e->getStatus());
            $response = new Genghis_JsonResponse(array('error' => $msg), $e->getStatus());
            $response->render();
        }
    }

    public function route($method, $path)
    {
        if (preg_match(self::CHECK_STATUS_ROUTE, $path)) {
            return $this->checkStatus();
        }

        $p = array();
        if (preg_match(self::ROUTE_PATTERN, $path, $p)) {
            foreach ($p as $i => $val) {
                if (is_numeric($i) || empty($val)) {
                    unset($p[$i]);
                }
            }

            if (isset($p['documents'])) {
                if (isset($p['document'])) {
                    switch ($method) {
                        case 'GET':
                            return $this->findDocument($p['server'], $p['database'], $p['collection'], $p['document']);
                        case 'PUT':
                            return $this->updateDocument($p['server'], $p['database'], $p['collection'], $p['document'], $this->getRequestData(true));
                        case 'DELETE':
                            return $this->removeDocument($p['server'], $p['database'], $p['collection'], $p['document']);
                        default:
                            throw new Genghis_HttpException(405);
                    }
                } else {
                    switch ($method) {
                        case 'GET':
                            return $this->findDocuments(
                                $p['server'], $p['database'], $p['collection'],
                                (string) $this->getQueryParam('q', ''),
                                (int) $this->getQueryParam('page', 1)
                            );
                        case 'POST':
                            return $this->insertDocument($p['server'], $p['database'], $p['collection'], $this->getRequestData());
                        case 'DELETE':
                            return $this->truncateCollection($p['server'], $p['database'], $p['collection']);
                        default:
                            throw new Genghis_HttpException(405);
                    }
                }
            } elseif (isset($p['collections'])) {
                if (isset($p['collection'])) {
                    switch ($method) {
                        case 'GET':
                            return $this->selectCollection($p['server'], $p['database'], $p['collection']);
                        case 'DELETE':
                            return $this->dropCollection($p['server'], $p['database'], $p['collection']);
                        default:
                            throw new Genghis_HttpException(405);
                    }
                } else {
                    switch ($method) {
                        case 'GET':
                            return $this->listCollections($p['server'], $p['database']);
                        case 'POST':
                            return $this->createCollection($p['server'], $p['database'], $this->getRequestData());
                        default:
                            throw new Genghis_HttpException(405);
                    }
                }
            } elseif (isset($p['databases'])) {
                if (isset($p['database'])) {
                    switch ($method) {
                        case 'GET':
                            return $this->selectDatabase($p['server'], $p['database']);
                        case 'DELETE':
                            return $this->dropDatabase($p['server'], $p['database']);
                        default:
                            throw new Genghis_HttpException(405);
                    }
                } else {
                    switch ($method) {
                        case 'GET':
                            return $this->listDatabases($p['server']);
                        case 'POST':
                            return $this->createDatabase($p['server'], $this->getRequestData());
                        default:
                            throw new Genghis_HttpException(405);
                    }
                }
            } else {
                if (isset($p['server'])) {
                    switch ($method) {
                        case 'GET':
                            return $this->showServer($p['server']);
                        case 'DELETE':
                            return $this->removeServer($p['server']);
                        default:
                            throw new Genghis_HttpException(405);
                    }
                } else {
                    switch ($method) {
                        case 'GET':
                            return $this->listServers();
                        case 'POST':
                            return $this->addServer($this->getRequestData());
                        default:
                            throw new Genghis_HttpException(405);
                    }
                }
            }
        }

        throw new Genghis_HttpException(404);
    }

    protected function checkStatus()
    {
        $alerts = array();

        // check php status
        if (!class_exists('Mongo', false)) {
            $alerts[] = array(
                'level' => 'error',
                'msg'   => '<h4>Mongo PHP class not found.</h4> ' .
                           'Have you installed and enabled the <strong>PECL Mongo drivers</strong>?',
            );
        }

        // TODO: more sanity checks?

        return new Genghis_JsonResponse(compact('alerts'));
    }

    protected function listServers()
    {
        $this->initServers();

        $servers = array();
        foreach (array_keys($this->servers) as $name) {
            $servers[] = $this->dumpServer($name);
        }

        return new Genghis_JsonResponse($servers);
    }

    protected function addServer(array $data)
    {
        if (!isset($data['name'])) {
            throw new Genghis_HttpException(400, 'Server name must be specified');
        }

        $server = self::parseServerDsn($data['name']);

        $this->initServers();
        $this->servers[$server['name']] = $server;
        $this->saveServers();

        return $this->showServer($server['name']);
    }

    protected function removeServer($name)
    {
        $this->initServers();
        if (isset($this->servers[$name])) {
            unset($this->servers[$name]);
            $this->saveServers();

            return new Genghis_JsonResponse(array('success' => true));
        }

        throw new Genghis_HttpException(404, sprintf("Server '%s' not found", $name));
    }

    protected function showServer($name)
    {
        $this->initServers();
        if (!isset($this->servers[$name])) {
            throw new Genghis_HttpException(404, sprintf("Server '%s' not found", $name));
        }

        return new Genghis_JsonResponse($this->dumpServer($name));
    }

    protected function dumpServer($name)
    {
        $server = array(
            'id'       => $name,
            'name'     => $name,
            'editable' => !(isset($this->servers[$name]['default']) && $this->servers[$name]['default']),
        );

        if (isset($this->servers[$name]['error'])) {
            $server['error'] = $this->servers[$name]['error'];

            return $server;
        }

        try {
            $res = $this->getMongo($name)->listDBs();
            $dbs = array_map(function($db) {
                return $db['name'];
            }, $res['databases']);

            return array_merge($server, array(
                'size'      => $res['totalSize'],
                'count'     => count($dbs),
                'databases' => $dbs,
            ));
        } catch (Exception $e) {
            $server['error'] = 'Unable to connect to Mongo server at "'.$name.'".';

            return $server;
        }
    }

    protected function initServers()
    {
        if (!isset($this->servers)) {
            $defaultDsns = array_merge(
                isset($_ENV['GENGHIS_SERVERS'])    ? explode(';', $_ENV['GENGHIS_SERVERS'])    : array(),
                isset($_SERVER['GENGHIS_SERVERS']) ? explode(';', $_SERVER['GENGHIS_SERVERS']) : array()
            );

            foreach ($defaultDsns as $dsn) {
                try {
                    $server = self::parseServerDsn($dsn);
                } catch (Genghis_HttpException $e) {
                    $server = array(
                        'name'    => $dsn,
                        'dsn'     => $dsn,
                        'options' => array(),
                        'error'   => $e->getMessage(),
                    );
                }

                $server['default'] = true;
                $this->servers[$server['name']] = $server;
            }

            if (isset($_COOKIE['genghis_servers']) && $localDsns = $this->decodeJson($_COOKIE['genghis_servers'], false)) {
                foreach (array_map(array($this, 'parseServerDsn'), $localDsns) as $server) {
                    $this->servers[$server['name']] = $server;
                }
            }

            if (empty($this->servers)) {
                $this->servers['localhost'] = array(
                    'name' => 'localhost',
                    'dsn'  => 'localhost:27017',
                );
            }
        }
    }

    protected function saveServers()
    {
        $servers = array();
        foreach ($this->servers as $name => $server) {
            if (!isset($server['default']) || !$server['default']) {
                $servers[$name] = $server['dsn'];
            }
        }

        setcookie('genghis_servers', $this->encodeJson($servers, false), time()+60*60*24*365, '/');
    }

    public static function parseServerDsn($dsn)
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

    protected function dumpDatabase($server, $database)
    {
        $dbs = $this->getMongo($server)->listDBs();
        foreach ($dbs['databases'] as $db) {
            if ($db['name'] == $database) {
                $colls = array();
                foreach ($this->getDatabase($server, $database)->listCollections() as $coll) {
                    $colls[] = $coll->getName();
                }

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

    protected function selectDatabase($server, $database)
    {
        return new Genghis_JsonResponse($this->dumpDatabase($server, $database));
    }

    protected function dropDatabase($server, $database)
    {
        $this->getDatabase($server, $database)->drop();

        return new Genghis_JsonResponse(array('success' => true));
    }

    protected function listDatabases($server)
    {
        $dbs   = array();
        $mongo = $this->getMongo($server);
        $res   = $this->getMongo($server)->listDBs();
        foreach ($res['databases'] as $db) {
            $dbs[] = $this->dumpDatabase($server, $db['name']);
        }

        return new Genghis_JsonResponse($dbs);
    }

    protected function createDatabase($server, array $data)
    {
        if (!isset($data['name'])) {
            throw new HttpException(400, 'Database name must be specified');
        }

        $conn = $this->getMongo($server);
        if ($this->hasDatabase($conn, $data['name'])) {
            throw new Genghis_HttpException(500, sprintf("Database '%s' already exists", $data['name']));
        }

        $conn->selectDB($data['name'])->selectCollection('__genghis_tmp_collection__')->drop();

        return $this->selectDatabase($server, $data['name']);
    }

    protected function dumpCollection($server, $database, $collection)
    {
        foreach ($this->getDatabase($server, $database)->listCollections() as $coll) {
            if ($coll->getName() == $collection) {
                return array(
                    'id'      => $coll->getName(),
                    'name'    => $coll->getName(),
                    'count'   => $coll->count(),
                    'indexes' => $coll->getIndexInfo(),
                );
            }
        }

        throw new Genghis_HttpException(404, sprintf("Collection '%s' not found in '%s'", $collection, $database));
    }

    public function selectCollection($server, $database, $collection)
    {
        return new Genghis_JsonResponse($this->dumpCollection($server, $database, $collection));
    }

    public function truncateCollection($server, $database, $collection)
    {
        $this->getCollection($server, $database, $collection)->remove(array());

        return $this->selectCollection($server, $database, $collection);
    }

    public function dropCollection($server, $database, $collection)
    {
        $this->getCollection($server, $database, $collection)->drop();

        return new Genghis_JsonResponse(array('success' => true));
    }

    public function listCollections($server, $database)
    {
        $colls = array();
        foreach ($this->getDatabase($server, $database)->listCollections() as $coll) {
            $colls[] = $this->dumpCollection($server, $database, $coll->getName());
        }

        return new Genghis_JsonResponse($colls);
    }

    public function createCollection($server, $database, array $data = array())
    {
        if (!isset($data['name'])) {
            throw new Genghis_HttpException(400, 'Collection name must be specified');
        }

        $this->getDatabase($server, $database)->createCollection($data['name']);

        return $this->selectCollection($server, $database, $data['name']);
    }

    public function findDocument($server, $database, $collection, $document)
    {
        $doc = $this->getCollection($server, $database, $collection)->findOne(array(
            '_id' => $this->thunkMongoId($document),
        ));

        if ($doc) {
            return new Genghis_JsonResponse($doc);
        }

        throw new Genghis_HttpException(404, sprintf("Document '%s' not found in '%s'", $document, $collection));
    }

    public function updateDocument($server, $database, $collection, $document, $data)
    {
        $coll  = $this->getCollection($server, $database, $collection);
        $query = array('_id' => $this->thunkMongoId($document));

        if ($coll->findOne($query)) {
            $result = $coll->update($query, $data, array('safe' => true));

            if (!(isset($result['ok']) && $result['ok'])) {
                throw new Genghis_HttpException;
            }

            return $this->findDocument($server, $database, $collection, $document);
        }

        throw new Genghis_HttpException(404, sprintf("Document '%s' not found in '%s'", $document, $collection));
    }

    public function removeDocument($server, $database, $collection, $document)
    {
        $coll  = $this->getCollection($server, $database, $collection);
        $query = array('_id' => $this->thunkMongoId($document));

        if ($coll->findOne($query)) {
            $result = $coll->remove($query, array('safe' => true));

            if (!(isset($result['ok']) && $result['ok'])) {
                throw new Genghis_HttpException;
            }

            return new Genghis_JsonResponse(array('success' => true));
        }

        throw new Genghis_HttpException(404, sprintf("Document '%s' not found in '%s'", $document, $collection));
    }

    public function findDocuments($server, $database, $collection, $query = null, $page = 1)
    {
        $offset = self::PAGE_LIMIT * ($page - 1);
        $cursor = $this->getCollection($server, $database, $collection)
            ->find($query ? $this->decodeJson($query) : array())
            ->limit(self::PAGE_LIMIT)
            ->skip($offset);

        $count = $cursor->count();

        return new Genghis_JsonResponse(array(
            'count'     => $count,
            'page'      => $page,
            'pages'     => max(1, ceil($count / self::PAGE_LIMIT)),
            'per_page'  => self::PAGE_LIMIT,
            'offset'    => $offset,
            'documents' => array_values(iterator_to_array($cursor)),
        ));
    }

    public function insertDocument($server, $database, $collection, $data = null)
    {
        if (empty($data)) {
            throw new Genghis_HttpException(400, 'Malformed document');
        }

        $result = $this->getCollection($server, $database, $collection)
            ->insert($data, array('safe' => true));

        if (!(isset($result['ok']) && $result['ok'])) {
            throw new Genghis_HttpException;
        }

        return new Genghis_JsonResponse($data);
    }

    protected function encodeJson($value, $gfj = true)
    {
        if ($gfj) {
            return Genghis_Json::encode($value);
        } else {
            return json_encode($value);
        }
    }

    protected function decodeJson($data, $gfj = true)
    {
        if ($gfj) {
            try {
                return Genghis_Json::decode($data);
            } catch (Genghis_JsonException $e) {
                throw new Genghis_HttpException(400, 'Malformed document');
            }
        } else {
            $json = json_decode($data, true);
            if ($json === false && trim($data) != '') {
                throw new Genghis_HttpException(400, 'Malformed document');
            }

            return $json;
        }
    }

    protected function thunkMongoId($id)
    {
        return preg_match('/^[a-f0-9]{24}$/i', $id) ? new MongoId($id) : $id;
    }

    protected function getRequestData($gfj = false)
    {
        return $this->decodeJson(file_get_contents('php://input'), $gfj);
    }

    protected function getMongo($server)
    {
        $this->initServers();

        if (!isset($this->servers[$server])) {
            throw new Genghis_HttpException(404, sprintf("Server '%s' not found", $server));
        }

        $server = $this->servers[$server];

        return new Mongo($server['dsn'], isset($server['options']) ? $server['options'] : array());
    }

    protected function getDatabase($server, $database)
    {
        $conn = $this->getMongo($server);
        if (!$this->hasDatabase($conn, $database)) {
            throw new Genghis_HttpException(404, sprintf("Database '%s' not found on '%s'", $database, $server));
        }

        return $conn->selectDB($database);
    }

    protected function hasDatabase($connection, $database)
    {
        $dbs = $connection->listDBs();
        foreach ($dbs['databases'] as $db) {
            if ($db['name'] === $database) {
                return true;
            }
        }

        return false;
    }

    protected function getCollection($server, $database, $collection)
    {
        foreach ($this->getDatabase($server, $database)->listCollections() as $coll) {
            if ($coll->getName() === $collection) {
                return $coll;
            }
        }

        throw new Genghis_HttpException(404, sprintf("Collection '%s' not found in '%s'", $collection, $database));
    }
}
