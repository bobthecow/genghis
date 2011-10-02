<?php

class HttpException extends Exception
{
    protected $status;

    public function __construct($status = 500, $msg = '')
    {
        $this->status = $status;
        parent::__construct(empty($msg) ? Response::getStatusText($status) : $msg);
    }

    public function getStatus()
    {
        return $this->status;
    }
}
