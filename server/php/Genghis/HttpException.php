<?php

class Genghis_HttpException extends Exception
{
    protected $status;

    public function __construct($status = 500, $msg = '')
    {
        $this->status = $status;
        parent::__construct(empty($msg) ? Genghis_Response::getStatusText($status) : $msg);
    }

    public function getStatus()
    {
        return $this->status;
    }
}
