<?php

class Genghis_JsonRegex
{
    public $pattern;

    public function __construct($pattern)
    {
        $this->pattern = $pattern;
    }

    public function __toString()
    {
        return $this->getPattern();
    }
}
