<?php

class Genghis_Api extends Genghis_App
{
    // api/servers/:server/databases/:db/collections/:coll/documents/:id
    const ROUTE_PATTERN = '~^/?servers(?:/(?P<server>[^/]+)(?P<databases>/databases(?:/(?P<db>[^/]+)(?P<collections>/collections(?:/(?P<coll>[^/]+)((?P<documents>/documents(?:/(?P<id>[^/]+))?)?|(?P<explain>/explain)?)?)?)?)?)?)?/?$~';

    // api/servers/:server/databases/:db/collections/:coll/files/:id
    const GRIDFS_ROUTE = '~^/?servers/(?P<server>[^/]+)/databases/(?P<db>[^/]+)/collections/(?P<coll>[^/]+)/files(?:/(?P<id>[^/]+))?/?$~';

    const CHECK_STATUS_ROUTE = '~/?check-status/?$~';

    const PAGE_LIMIT = 50;

    protected $servers;

    public function __construct()
    {
        $this->servers = new Genghis_ServerCollection;
    }

    public function route($method, $path)
    {
        try {
            try {
                return $this->doRoute($method, $path);
            } catch (Genghis_HttpException $e) {
                return $this->errorResponse($e->getMessage(), $e->getStatus());
            }
        } catch (Exception $e) {
            return $this->errorResponse($e->getMessage());
        }
    }

    public function doRoute($method, $path)
    {
        if (preg_match(self::CHECK_STATUS_ROUTE, $path)) {
            return new Genghis_JsonResponse($this->checkStatusAction());
        }

        $p = array();
        if (preg_match(self::ROUTE_PATTERN, $path, $p)) {
            $p = array_map('urldecode', array_filter($p));

            if (isset($p['id'])) {
                return new Genghis_JsonResponse($this->documentAction($method, $p['server'], $p['db'], $p['coll'], $p['id']));
            }

            if (isset($p['explain'])) {
                return new Genghis_JsonResponse($this->explainAction($method, $p['server'], $p['db'], $p['coll']));
            }

            if (isset($p['documents'])) {
                return new Genghis_JsonResponse($this->documentsAction($method, $p['server'], $p['db'], $p['coll']));
            }

            if (isset($p['coll'])) {
                return new Genghis_JsonResponse($this->collectionAction($method, $p['server'], $p['db'], $p['coll']));
            }

            if (isset($p['collections'])) {
                return new Genghis_JsonResponse($this->collectionsAction($method, $p['server'], $p['db']));
            }

            if (isset($p['db'])) {
                return new Genghis_JsonResponse($this->databaseAction($method, $p['server'], $p['db']));
            }

            if (isset($p['databases'])) {
                return new Genghis_JsonResponse($this->databasesAction($method, $p['server']));
            }

            if (isset($p['server'])) {
                return new Genghis_JsonResponse($this->serverAction($method, $p['server']));
            }

            return new Genghis_JsonResponse($this->serversAction($method));
        }

        $p = array();
        if (preg_match(self::GRIDFS_ROUTE, $path, $p)) {
            $p = array_map('urldecode', array_filter($p));

            if (isset($p['id'])) {
                $file = $this->fileAction($method, $p['server'], $p['db'], $p['coll'], $p['id']);

                return ($method === 'GET') ? new Genghis_GridFsResponse($file) : new Genghis_JsonResponse($file);
            } else {
                return new Genghis_JsonResponse($this->filesAction($method, $p['server'], $p['db'], $p['coll']));
            }
        }

        throw new Genghis_HttpException(404);
    }

    protected function checkStatusAction()
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

        // check for updates
        if (!$this->skipUpdateCheck()) {
            try {
                $latest = @file_get_contents('https://raw.github.com/bobthecow/genghis/master/VERSION');
                if ($latest && version_compare($latest, GENGHIS_VERSION, '>')) {
                    $alerts[] = array(
                        'level' => 'warning',
                        'msg'   => '<h4>A Genghis update is available</h4> ' .
                                   'You are running Genghis version <tt>' . GENGHIS_VERSION . '</tt>. ' .
                                   'The current version is <tt>' . $latest . '</tt>. ' .
                                   'Visit <a href="http://genghisapp.com">genghisapp.com</a> for more information.'
                    );
                }
            } catch (Exception $e) {
                // do nothing
            }
        }

        // Check for Timezone issues
        try {
            $d = new DateTime;
        } catch (Exception $e) {
            $msg = $e->getMessage();

            if (strpos($msg, 'date.timezone') === false) {
                throw $e;
            }

            $alerts[] = array(
                'level' => 'warning',
                'msg'   => preg_replace('/^(?:(?:DateTime::__construct\(\))?: )?([^\.]+\.)/', '<h4>\1</h4> ', $msg),
            );
        }

        // Check for magic quotes
        if (get_magic_quotes_gpc()) {
            $alerts[] = array(
                'level' => 'error',
                'msg'   => '<h4>Looks like you\'re rockin\' it retro style</h4>' .
                           'You are running PHP with <tt>magic_quotes_gpc</tt> enabled. Not only is this ' .
                           '<a href="http://us1.php.net/manual/en/security.magicquotes.php">dangerous and ' .
                           'deprecated</a>, but it will keep Genghis from properly querying and saving documents. ' .
                           'Please <a href="http://us1.php.net/manual/en/security.magicquotes.disabling.php">disable ' .
                           '<tt>magic_quotes_gpc</tt></a>.',
            );
        }

        if (get_magic_quotes_runtime()) {
            $alerts[] = array(
                'level' => 'error',
                'msg'   => '<h4>Looks like you\'re rockin\' it retro style</h4>' .
                           'You are running PHP with <tt>magic_quotes_runtime</tt> enabled. Not only is this ' .
                           '<a href="http://us1.php.net/manual/en/security.magicquotes.php">dangerous and ' .
                           'deprecated</a>, but it will keep Genghis from properly querying and saving documents. ' .
                           'Please <a href="http://us1.php.net/manual/en/info.configuration.php#ini.magic-quotes-runtime">disable ' .
                           '<tt>magic_quotes_runtime</tt></a>.',
            );
        }

        // TODO: more sanity checks?

        return compact('alerts');
    }

    public function documentAction($method, $server, $db, $coll, $id)
    {
        switch ($method) {
            case 'GET':
                return $this->servers[$server][$db][$coll][$id];

            case 'PUT':
                $this->servers[$server][$db][$coll][$id] = $this->getRequestData();

                return $this->servers[$server][$db][$coll][$id];

            case 'DELETE':
                unset($this->servers[$server][$db][$coll][$id]);

                return array('success' => true);

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function explainAction($method, $server, $db, $coll)
    {
        switch ($method) {
            case 'GET':
                $query = (string) $this->getQueryParam('q', '');

                return $this->servers[$server][$db][$coll]->explainQuery($query);

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function documentsAction($method, $server, $db, $coll)
    {
        switch ($method) {
            case 'GET':
                $query = (string) $this->getQueryParam('q', '');
                $page  = (int) $this->getQueryParam('page', 1);

                return $this->servers[$server][$db][$coll]->findDocuments($query, $page);

            case 'POST':
                return $this->servers[$server][$db][$coll]->insert($this->getRequestData());

            case 'DELETE':
                $this->servers[$server][$db][$coll]->truncate();

                return array('success' => true);

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function collectionAction($method, $server, $db, $coll)
    {
        switch ($method) {
            case 'GET':
                return $this->servers[$server][$db][$coll];

            case 'DELETE':
                unset($this->servers[$server][$db][$coll]);

                return array('success' => true);

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function collectionsAction($method, $server, $db)
    {
        switch ($method) {
            case 'GET':
                return $this->servers[$server][$db]->listCollections();

            case 'POST':
                return $this->servers[$server][$db]->createCollection($this->getRequestParam('name'));

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function databaseAction($method, $server, $db)
    {
        switch ($method) {
            case 'GET':
                return $this->servers[$server][$db];

            case 'DELETE':
                unset($this->servers[$server][$db]);

                return array('success' => true);

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function databasesAction($method, $server)
    {
        switch ($method) {
            case 'GET':
                return $this->servers[$server]->listDatabases();

            case 'POST':
                return $this->servers[$server]->createDatabase($this->getRequestParam('name'));

            default:
                throw new Genghis_HttpException(405);
        }

    }

    public function serverAction($method, $server)
    {
        switch ($method) {
            case 'GET':
                return $this->servers[$server];

            case 'DELETE':
                unset($this->servers[$server]);

                return array('success' => true);

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function serversAction($method)
    {
        switch ($method) {
            case 'GET':
                return $this->servers;

            case 'POST':
                $server = new Genghis_Models_Server($this->getRequestParam('name'));
                if ($server->error) {
                    throw new Genghis_HttpException(400, $server->error);
                }

                $this->servers[] = $server;

                return $server;

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function fileAction($method, $server, $db, $coll, $id)
    {
        switch ($method) {
            case 'GET':
                return $this->servers[$server][$db][$coll]->getFile($id);

            case 'DELETE':
                $this->servers[$server][$db][$coll]->deleteFile($id);

                return array('success' => true);

            default:
                throw new Genghis_HttpException(405);
        }
    }

    public function filesAction($method, $server, $db, $coll)
    {
        switch ($method) {
            case 'POST':
                return $this->servers[$server][$db][$coll]->putFile($this->getRequestData());

            default:
                throw new Genghis_HttpException(405);
        }
    }

    protected function skipUpdateCheck()
    {
        return (isset($_ENV['GENGHIS_NO_UPDATE_CHECK']) && $_ENV['GENGHIS_NO_UPDATE_CHECK'])
            || (isset($_SERVER['GENGHIS_NO_UPDATE_CHECK']) && $_SERVER['GENGHIS_NO_UPDATE_CHECK']);
    }

    protected function getRequestData($gfj = true)
    {
        $data = file_get_contents('php://input');

        if ($gfj) {
            try {
                $json = Genghis_Json::decode($data);
            } catch (Genghis_JsonException $e) {
                throw new Genghis_HttpException(400, 'Malformed document');
            }
        } else {
            $json = json_decode($data, true);
        }

        if (empty($json)) {
            throw new Genghis_HttpException(400, 'Malformed document');
        }

        return $json;
    }

    protected function getRequestParam($name)
    {
        $data = $this->getRequestData(false);

        if (!isset($data[$name])) {
            throw new HttpException(400, sprintf("'%s' must be specified", $name));
        }

        return $data[$name];
    }

    protected function errorResponse($msg, $status = 500)
    {
        if (empty($msg)) {
            $msg = Genghis_Response::getStatusText($status);
        }

        return new Genghis_JsonResponse(array('error' => $msg, 'status' => $status), $status);
    }
}
