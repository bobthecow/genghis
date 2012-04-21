<?php

class Genghis_Response
{
    protected static $statusCodes = array(
        200 => 'OK',
        201 => 'Created',
        202 => 'Accepted',
        204 => 'No Content',
        301 => 'Moved Permanently',
        302 => 'Found',
        303 => 'See Other',
        304 => 'Not Modified',
        400 => 'Bad Request',
        401 => 'Unauthorized',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        406 => 'Not Acceptable',
        412 => 'Precondition Failed',
        415 => 'Unsupported Media Type',
        417 => 'Expectation Failed',
        500 => 'Internal Server Error',
        501 => 'Not Implemented',
    );

    protected $data    = '';
    protected $status  = 200;
    protected $headers = array();

    public function __construct($data, $status = 200, $headers = array())
    {
        $this->data    = $data;
        $this->status  = $status;
        $this->headers = $headers;
    }

    public function render()
    {
        $this->renderHeaders();
        $this->renderContent();
    }

    public static function getStatusText($status)
    {
        if (isset(self::$statusCodes[$status])) {
            return self::$statusCodes[$status];
        }
    }

    protected function renderHeaders()
    {
        header(sprintf('HTTP/1.0 %s %s', $this->status, self::$statusCodes[$this->status]));
        foreach ($this->headers as $name => $val) {
            header(sprintf('%s: %s', $name, $val));
        }
    }

    protected function renderContent()
    {
        print((string) $this->data);
    }
}
