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

        $method = $this->getRequestMethod();
        $path   = $this->getRequestPath();
        try {
            $response = $this->route($method, $path);
            if ($response instanceof Genghis_Response) {
                $this->logResponse($method, $path, $response);
                $response->render();
            } else {
                throw new Genghis_HttpException(500);
            }
        } catch (Genghis_HttpException $e) {
            $this->logException($e, $e->getStatus());
            $this->errorResponse($e->getMessage(), $e->getStatus())->render();
        } catch (Exception $e) {
            $this->logException($e);
            $this->errorResponse($e->getMessage(), 703)->render();
        }
    }

    public function route($method, $path)
    {
        if ($this->isJsonRequest() || $this->isGridFsRequest()) {
            return $this->getApi()->route($method, $path);
        } elseif ($this->isAssetRequest($path)) {
            return $this->getAsset($path);
        } else {
            // not an api request, we'll return index and render the page in javascript.
            return $this->renderTemplate('index.mustache');
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
        return preg_match('#^/(js|css|img)/#', $path);
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
            return $this->loader->load(substr($name, 1));
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
        return $this->renderTemplate('error.mustache', $status, compact('message', 'status'));
    }

    protected function logResponse($method, $path, Genghis_Response $response)
    {
        $isApi  = !($response instanceof Genghis_AssetResponse);
        $status = $response->getStatus();

        $msg = sprintf(
            "%s [%d]: %s %s",
            $_SERVER['HTTP_HOST'],
            $status,
            $method,
            $path
        );

        $this->log($this->formatLine($status, $isApi, $msg));
    }

    protected function logException(Exception $e, $status = 500)
    {
        $msg = sprintf(
            "%s [%d]: %s",
            $_SERVER['HTTP_HOST'],
            $status,
            $e->getMessage()
        );

        $this->log($this->colorText(self::RED, $msg));
    }

    protected function log($line)
    {
        if (!isset($this->log)) {
            $this->log = fopen('php://stderr', 'w');
        }

        $date   = new DateTime;
        $prefix = $date->format('[D M d H:i:s Y] ');

        fwrite($this->log, $prefix . $line . PHP_EOL);
    }

    const BLACK   = 30;
    const RED     = 31;
    const GREEN   = 32;
    const YELLOW  = 33;
    const BLUE    = 34;
    const MAGENTA = 35;
    const CYAN    = 36;
    const WHITE   = 37;

    protected function formatLine($status, $isApi, $text)
    {
        if ($status >= 200 && $status < 300) {
            $color = $isApi ? self::BLUE : self::GREEN;
        } elseif ($status >= 400 && $status < 500) {
            $color = self::YELLOW;
        } else {
            $color = self::WHITE;
        }

        return $this->colorText($color, $text);
    }

    protected function colorText($color, $text)
    {
        if (php_sapi_name() !== 'cli') {
            return $text;
        }

        return sprintf("\033[%sm%s\033[0m", $color, $text);
    }
}
