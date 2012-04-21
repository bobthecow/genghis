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
        // json encoding a MongoId with PECL Mongo driver < 1.0.11 returns '{}' ...
        if (version_compare(Mongo::VERSION, '1.0.11', '<')) {
            array_walk_recursive($this->data, array(__CLASS__, 'prepareData'), ini_get('mongo.cmd'));
        }

        print(json_encode($this->data));
    }

    private static function prepareData(&$data, $key, $cmd = '$')
    {
        if (is_object($data) && $data instanceof MongoId) {
            $data = array($cmd.'id' => (string) $data);
        }
    }
}
