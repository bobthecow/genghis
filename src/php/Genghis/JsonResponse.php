<?php

class Genghis_JsonResponse extends Genghis_Response
{
    public function renderHeaders()
    {
        $this->headers['Content-type']  = 'application/json';
        $this->headers['Cache-Control'] = 'no-cache, must-revalidate';
        $this->headers['Expires']       = 'Wed, 04 Aug 1982 00:00:00 GMT';

        parent::renderHeaders();
    }

    public function renderContent()
    {
        print(Genghis_Json::encode($this->data));
    }
}
