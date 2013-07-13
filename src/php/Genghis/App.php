<?php

class Genghis_App
{
    protected $loader;
    protected $baseUrl;

    public function __construct(Genghis_AssetLoader $loader)
    {
        $this->loader = $loader;
    }

    public function run()
    {
        set_error_handler(array('Genghis_ErrorException', 'throwException'));

        try {
            $response = $this->route($this->getRequestMethod(), $this->getRequestPath());
            if ($response instanceof Genghis_Response) {
                $response->render();
            } else {
                throw new Genghis_HttpException(500);
            }
        } catch (Genghis_HttpException $e) {
            $this->errorResponse($e->getMessage(), $e->getStatus())->render();
        } catch (Exception $e) {
            $this->errorResponse($e->getMessage())->render();
        }
    }

    public function route($method, $path)
    {
        if ($this->isJsonRequest() || $this->isGridFsRequest()) {
            return $this->getApi()->route($method, $path);
        } elseif ($this->isAssetRequest($path)) {
            return $this->getAsset(substr($path, 8));
        } elseif (substr($path, -11) === 'VERSION.txt') {
            return new Genghis_AssetResponse('VERSION.txt', GENGHIS_VERSION);
        } else {
            // not an api request, we'll return index.html and render the page in javascript.
            return $this->renderTemplate('index.html.mustache');
        }
    }

    protected function isJsonRequest()
    {
        if (in_array($this->getRequestMethod(), array('POST', 'PUT'))) {
            if (array_key_exists('HTTP_CONTENT_TYPE', $_SERVER)) {
                $type = $_SERVER['HTTP_CONTENT_TYPE'];
            } elseif (array_key_exists('CONTENT_TYPE', $_SERVER)) {
                $type = $_SERVER['CONTENT_TYPE'];
            } else {
                $type = 'x-www-form-urlencoded';
            }
        } else {
            $type = isset($_SERVER['HTTP_ACCEPT']) ? $_SERVER['HTTP_ACCEPT'] : 'text/html';
        }

        return strpos($type, 'application/json') !== false || strpos($type, 'application/javascript') !== false;
    }

    protected function isGridFsRequest()
    {
        return $this->getRequestMethod() == 'GET' && preg_match(Genghis_Api::GRIDFS_ROUTE, $this->getRequestPath());
    }

    protected function isAssetRequest($path)
    {
        return (strpos($path, '/assets/') === 0);
    }

    protected function getBaseUrl()
    {
        if (!isset($this->baseUrl)) {
            $this->baseUrl = $this->prepareBaseUrl();
        }

        return $this->baseUrl;
    }

    protected function prepareBaseUrl()
    {
        $filename = basename($_SERVER['SCRIPT_FILENAME']);

        foreach (array('SCRIPT_NAME', 'PHP_SELF', 'ORIG_SCRIPT_NAME') as $key) {
            if (isset($_SERVER[$key]) && basename($_SERVER[$key]) == $filename) {
                $baseUrl = $_SERVER[$key];
                break;
            }
        }

        if (!isset($baseUrl)) {
            $path    = isset($_SERVER['PHP_SELF']) ? $_SERVER['PHP_SELF'] : '';
            $file    = isset($_SERVER['SCRIPT_FILENAME']) ? $_SERVER['SCRIPT_FILENAME'] : '';
            $chunks  = array_reverse(explode('/', trim($file, '/')));
            $index   = 0;
            $last    = count($chunks);
            $baseUrl = '';
            do {
                $seg     = $chunks[$index];
                $baseUrl = '/'.$seg.$baseUrl;
                ++$index;
            } while (($last > $index) && (false !== ($pos = strpos($path, $baseUrl))) && (0 != $pos));
        }

        // Does the baseUrl have anything in common with the request_uri?
        $requestUri = $_SERVER['REQUEST_URI'];

        if ($baseUrl && 0 === strpos($requestUri, $baseUrl)) {
            // full $baseUrl matches
            return $baseUrl;
        }

        if ($baseUrl && 0 === strpos($requestUri, dirname($baseUrl))) {
            // directory portion of $baseUrl matches
            return rtrim(dirname($baseUrl), '/');
        }

        $truncatedRequestUri = $requestUri;
        if (($pos = strpos($requestUri, '?')) !== false) {
            $truncatedRequestUri = substr($requestUri, 0, $pos);
        }

        $basename = basename($baseUrl);
        if (empty($basename) || !strpos($truncatedRequestUri, $basename)) {
            // no match whatsoever; set it blank
            return '';
        }

        // If using mod_rewrite or ISAPI_Rewrite strip the script filename
        // out of baseUrl. $pos !== 0 makes sure it is not matching a value
        // from PATH_INFO or QUERY_STRING
        if ((strlen($requestUri) >= strlen($baseUrl)) && ((false !== ($pos = strpos($requestUri, $baseUrl))) && ($pos !== 0))) {
            $baseUrl = substr($requestUri, 0, $pos + strlen($baseUrl));
        }

        return rtrim($baseUrl, '/');
    }

    protected function getRequestMethod()
    {
        return $_SERVER['REQUEST_METHOD'];
    }

    protected function getRequestPath()
    {
        if (isset($_SERVER['PATH_INFO'])) {
            return $_SERVER['PATH_INFO'];
        } elseif (isset($_SERVER['REQUEST_URI'])) {
            return parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        } else {
            return '/';
        }
    }

    protected function getQueryParams()
    {
        global $_GET;

        return $_GET;
    }

    protected function getQueryParam($name, $default = null)
    {
        $params = $this->getQueryParams();
        if (isset($params[$name])) {
            return $params[$name];
        } else {
            return $default;
        }
    }

    protected function renderTemplate($name, $status = 200, array $vars = array())
    {
        $tpl = $this->loader->loadTemplate($name);
        $defaults = array(
            'base_url'        => $this->getBaseUrl(),
            'genghis_version' => GENGHIS_VERSION,
        );

        return new Genghis_Response(strtr($tpl, $this->prepareVars(array_merge($defaults, $vars))), $status);
    }

    protected function prepareVars($vars)
    {
        $ret = array();
        foreach ($vars as $name => $var) {
            $ret['{{ '.$name.' }}'] = $var;
        }

        return $ret;
    }

    protected function getAsset($name)
    {
        try {
            return $this->loader->load($name);
        } catch (InvalidArgumentException $e) {
            throw new Genghis_HttpException(404);
        }
    }

    protected function getApi()
    {
        return new Genghis_Api;
    }

    protected function errorResponse($message, $status = 500)
    {
        return $this->renderTemplate('error.html.mustache', $status, compact('message', 'status'));
    }
}
