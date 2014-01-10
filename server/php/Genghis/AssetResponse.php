<?php

class Genghis_AssetResponse extends Genghis_Response
{
    protected $headers;

    private static $extMap = array(
        'css'  => 'text/css',
        'gif'  => 'image/gif',
        'htm'  => 'text/html',
        'html' => 'text/html',
        'js'   => 'application/x-javascript',
        'json' => 'application/json',
        'php'  => 'text/html',
        'png'  => 'image/png',
        'txt'  => 'text/plain',
    );

    public function __construct($name, $content, $headers = array())
    {
        $this->name = $name;
        parent::__construct($content, 200, array_merge(array('Content-type' => $this->getContentType()), $headers));
    }

    protected function getContentType()
    {
        $parts = explode('.', $this->name);
        $ext   = end($parts);

        if (isset(self::$extMap[$ext])) {
            return self::$extMap[$ext];
        } else {
            return 'unknown/' . trim($ext);
        }
    }
}
