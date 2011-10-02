<?php

class RedirectResponse extends Response
{
    public function __construct($url, $status = 301)
    {
        parent::__construct($url, $status);
    }

    public function render()
    {
        header(sprintf('Location: %s', $this->data), $this->status);
    }
}
