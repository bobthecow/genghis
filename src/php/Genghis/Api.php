<?php

class Genghis_Api extends Genghis_App
{
    // api/servers/:serverName/databases/:databaseName/collections/:collectionName/documents/:documentId
    const ROUTE_PATTERN = '~^/?servers(?:/(?P<server>[^/]+)(?P<databases>/databases(?:/(?P<database>[^/]+)(?P<collections>/collections(?:/(?P<collection>[^/]+)(?P<documents>/documents(?:/(?P<document>[^/]+))?)?)?)?)?)?)?/?$~';

    // convert-json
    const CONVERT_JSON_ROUTE = '~/?convert-json/?$~';

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

        if (preg_match(self::CONVERT_JSON_ROUTE, $path)) {
            $decoder = new Genghis_JsonDecoder;

            return new Genghis_JsonResponse($decoder->decode(file_get_contents('php://input')));
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
                            return $this->updateDocument($p['server'], $p['database'], $p['collection'], $p['document'], $this->getRequestData());
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
                'msg'   => '<strong>Mongo PHP class not found.</strong> ' .
                           'Have you installed and enabled the PECL Mongo drivers?',
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

        $dsn = $data['name'];
        if (strpos($dsn, '://') === false) {
            $dsn = 'mongodb://'.$dsn;
        } else if (strpos($dsn, 'mongodb://') !== 0) {
            throw new Genghis_HttpException(400, 'Malformed server dsn');
        }

        $chunks = parse_url($dsn);
        if ($chunks === false || isset($chunks['query']) || isset($chunks['fragment']) || !isset($chunks['host'])) {
            throw new Genghis_HttpException(400, 'Malformed server dsn');
        }

        $name = $chunks['host'];
        if (isset($chunks['user'])) {
            $name = $chunks['user'].'@'.$name;
        }
        if (isset($chunks['port']) && $chunks['port'] !== 27017) {
            $name .= ':'.$chunks['port'];
        }

        $this->initServers();
        $this->servers[$name] = $dsn;
        $this->saveServers();

        return $this->showServer($name);
    }

    protected function removeServer($name)
    {
        $this->initServers();
        if (isset($this->servers[$name])) {
            unset($this->servers[$name]);
            $this->saveServers();

            return new Genghis_JsonResponse(array('success' => true));
        }

        throw new Genghis_HttpException(404);
    }

    protected function showServer($name)
    {
        $this->initServers();
        if (isset($this->servers[$name])) {
            return new Genghis_JsonResponse($this->dumpServer($name));
        } else {
            throw new Genghis_HttpException(404);
        }
    }

    protected function dumpServer($name)
    {
        try {
            $res = $this->getMongo($name)->listDBs();
            $dbs = array_map(function($db) {
                return $db['name'];
            }, $res['databases']);

            return array(
                'id'        => $name,
                'name'      => $name,
                'size'      => $res['totalSize'],
                'count'     => count($dbs),
                'databases' => $dbs,
            );
        } catch (Exception $e) {
            return array(
                'id'    => $name,
                'name'  => $name,
                'error' => 'Unable to connect to Mongo server at "'.$name.'".',
            );
        }
    }

    protected function initServers()
    {
        if (!isset($this->servers)) {
            if (isset($_COOKIE['genghis_servers']) && $servers = json_decode($_COOKIE['genghis_servers'], true)) {
                $this->servers = $servers;
            } else {
                $this->servers = array('localhost' => 'localhost:27017');
            }
        }
    }

    protected function saveServers()
    {
        setcookie('genghis_servers', json_encode($this->servers), time()+60*60*24*365, '/');
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
    }

    protected function selectDatabase($server, $database)
    {
        if ($db = $this->dumpDatabase($server, $database)) {
            return new Genghis_JsonResponse($db);
        }
        throw new Genghis_HttpException(404);
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

        $this->getCollection($server, $data['name'], '__genghis_tmp_collection__')->drop();

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
    }

    public function selectCollection($server, $database, $collection)
    {
        if ($coll = $this->dumpCollection($server, $database, $collection)) {
            return new Genghis_JsonResponse($coll);
        }
        throw new Genghis_HttpException(404);
    }

    public function truncateCollection($server, $database, $collection)
    {
        if ($coll = $this->getCollection($server, $database, $collection)) {
            $coll->remove(array());

            return $this->selectCollection($server, $database, $collection);
        }
        throw new Genghis_HttpException(404);
    }

    public function dropCollection($server, $database, $collection)
    {
        if ($coll = $this->getCollection($server, $database, $collection)) {
            $coll->drop();

            return new Genghis_JsonResponse(array('success' => true));
        }
        throw new Genghis_HttpException(404);
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
            throw new Genghis_HttpException(400, 'Database name must be specified');
        }
        $this->getDatabase($server, $database)->createCollection($data['name']);

        return $this->selectCollection($server, $database, $data['name']);
    }

    public function findDocument($server, $database, $collection, $document)
    {
        $doc = $this->getCollection($server, $database, $collection)->findOne(array(
            '_id' => new MongoId($document),
        ));
        if ($doc) {
            return new Genghis_JsonResponse($doc);
        }
        throw new Genghis_HttpException(404);
    }

    public function updateDocument($server, $database, $collection, $document, array $data)
    {
        $coll = $this->getCollection($server, $database, $collection);
        $query = array('_id' => new MongoId($document));
        if ($coll->findOne($query)) {
            $result = $coll->update($query, $data, array('safe' => true));

            if (isset($result['ok']) && $result['ok']) {
                return $this->findDocument($server, $database, $collection, $document);
            } else {
                throw new Genghis_HttpException;
            }
        } else {
            throw new Genghis_HttpException(404);
        }
    }

    public function removeDocument($server, $database, $collection, $document)
    {
        $coll = $this->getCollection($server, $database, $collection);
        $query = array('_id' => new MongoId($document));
        if ($coll->findOne($query)) {
            $result = $coll->remove($query, array('safe' => true));

            if (isset($result['ok']) && $result['ok']) {
                return new Genghis_JsonResponse(array('success' => true));
            } else {
                throw new Genghis_HttpException;
            }
        } else {
            throw new Genghis_HttpException(404);
        }
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

    public function insertDocument($server, $database, $collection, array $data = null)
    {
        if (empty($data)) {
            throw new Genghis_HttpException(400, 'Malformed document');
        }

        $result = $this->getCollection($server, $database, $collection)
            ->insert($data, array('safe' => true));

        if (isset($result['ok']) && $result['ok']) {
            return new Genghis_JsonResponse($data);
        } else {
            throw new Genghis_HttpException;
        }
    }

    protected function decodeJson($data)
    {
        try {
            $decoder = new Genghis_JsonDecoder;

            return $this->thunkMongoQuery($decoder->decode($data));
        } catch (Genghis_JsonException $e) {
            throw new Genghis_HttpException(400, 'Malformed document');
        }
    }

    protected function thunkMongoQuery(array $query)
    {
        foreach ($query as $key => $val) {
            if (is_array($val)) {
                if (isset($val['$id']) && count($val) == 1) {
                    $query[$key] = new MongoId($val['$id']);
                } elseif (count($val) == 2 && isset($val['sec']) && isset($val['usec'])) {
                    $query[$key] = new MongoDate($val['sec'], $val['usec']);
                } else {
                    $query[$key] = $this->thunkMongoQuery($val);
                }
            } else if ($val instanceof Genghis_JsonRegex) {
                $query[$key] = new MongoRegex($val->pattern);
            }
        }

        return $query;
    }

    protected function getRequestData()
    {
        return $this->decodeJson(file_get_contents('php://input'));
    }

    protected function getMongo($server)
    {
        $this->initServers();
        if (isset($this->servers[$server])) {
            return new Mongo($this->servers[$server]);
        }
    }

    protected function getDatabase($server, $database)
    {
        return $this->getMongo($server)->selectDB($database);
    }

    protected function getCollection($server, $database, $collection)
    {
        return $this->getDatabase($server, $database)->selectCollection($collection);
    }
}
