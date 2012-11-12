<?php

class Genghis_ServerCollection implements ArrayAccess, Genghis_JsonEncodable
{
    private $serverDsns;
    private $servers;
    private $defaultServerDsns;
    private $defaultServers;

    public function __construct(array $servers = null, array $defaultServers = null)
    {
        $this->serverDsns        = $servers;
        $this->defaultServerDsns = $defaultServers;
    }

    public function offsetExists($name)
    {
        $this->initDsns();

        return isset($this->serverDsns[$name]) || isset($this->defaultServerDsns[$name]);
    }

    public function offsetGet($name)
    {
        $this->initServers();

        if (!isset($this[$name])) {
            throw new Genghis_HttpException(404, sprintf("Server '%s' not found", $name));
        }

        if (!isset($this->servers[$name])) {
            if (isset($this->serverDsns[$name])) {
                $this->servers[$name] = new Genghis_Models_Server($this->serverDsns[$name]);
            } elseif (isset($this->defaultServerDsns[$name])) {
                $this->servers[$name] = new Genghis_Models_Server($this->defaultServerDsns[$name], true);
            }
        }

        return $this->servers[$name];
    }

    public function offsetSet($name, $server)
    {
        $this->initServers();

        if (!$server instanceof Genghis_Models_Server) {
            throw new Exception('Invalid Server instance');
        }

        if (isset($this->serverDsns[$server->name])) {
            throw new Genghis_HttpException(400, sprintf("Server '%s' already exists", $server->name));
        }

        $this->serverDsns[$server->name] = $server->dsn;
        $this->servers[$server->name]    = $server;
        $this->saveServers();
    }

    public function offsetUnset($name)
    {
        $this->initServers();

        if (!isset($this->servers[$name])) {
            throw new Genghis_HttpException(404, sprintf("Server '%s' not found", $name));
        }

        unset($this->servers[$name]);
        $this->saveServers();
    }

    public function asJson()
    {
        $this->initServers();

        return array_values($this->servers);
    }

    private function initDsns()
    {
        if (!isset($this->serverDsns)) {
            $this->serverDsns = array();

            if (isset($_COOKIE['genghis_servers']) && $localDsns = $this->decodeJson($_COOKIE['genghis_servers'])) {
                foreach (array_map(array('Genghis_Models_Server', 'parseDsn'), $localDsns) as $info) {
                    $this->serverDsns[$info['name']] = $info['dsn'];
                }
            }
        }

        if (!isset($this->defaultServerDsns)) {
            $this->defaultServerDsns = array();

            $defaultDsns = array_merge(
                isset($_ENV['GENGHIS_SERVERS'])    ? explode(';', $_ENV['GENGHIS_SERVERS'])    : array(),
                isset($_SERVER['GENGHIS_SERVERS']) ? explode(';', $_SERVER['GENGHIS_SERVERS']) : array()
            );

            foreach (array_map(array('Genghis_Models_Server', 'parseDsn'), $defaultDsns) as $info) {
                $this->defaultServerDsns[$info['name']] = $info['dsn'];
            }
        }

        // Add a fallback for localhost
        if (empty($this->serverDsns) && empty($this->defaultServerDsns)) {
            $this[] = new Genghis_Models_Server('localhost:27017');
        }
    }

    private function initServers()
    {
        if (!isset($this->servers)) {
            $this->servers = array();
            $this->initDsns();

            // warm 'em up
            foreach (array_merge(array_keys($this->serverDsns), array_keys($this->defaultServerDsns)) as $name) {
                $this[$name];
            }
        }
    }

    private function decodeJson($data)
    {
        $json = json_decode($data, true);
        if ($json === false && trim($data) != '') {
            throw new Genghis_HttpException(400, 'Malformed document');
        }

        return $json;
    }

    private function saveServers()
    {
        $servers = array();
        foreach ($this->servers as $server) {
            if (!$server->default) {
                $servers[] = $server->dsn;
            }
        }

        setcookie('genghis_servers', json_encode($servers), time()+60*60*24*365, '/');
    }
}
