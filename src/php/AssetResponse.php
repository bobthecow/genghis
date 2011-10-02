<?php

class AssetResponse extends Response
{
    protected $headers;

    public function __construct($name, $content, $headers = array())
    {
        parent::__construct($content);
        $this->name    = $name;
        $this->headers = array_merge(array('Content-type' => $this->getContentType()), $headers);
    }

    protected function getContentType()
    {
        $ext = strtolower(end(explode('.', $this->name)));
        switch ($ext) {
            case "js":
                return "application/x-javascript";
            case "json":
                return "application/json";
            case "css":
                return "text/css";
            case "html":
            case "htm":
            case "php":
                return "text/html";
            case "txt":
                return "text/plain";
            default:
                return "unknown/" . trim($ext);
        }
    }
}