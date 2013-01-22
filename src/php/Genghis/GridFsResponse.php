<?php

class Genghis_GridFsResponse extends Genghis_Response
{
    public function renderHeaders()
    {
        $this->headers['Content-type']        = 'application/octet-stream';
        $this->headers['Content-Disposition'] = 'attachment';

        if ($filename = $this->data->getFilename()) {
            $this->headers['Content-Disposition'] .= sprintf('; filename="%s"', $filename);
        }

        parent::renderHeaders();
    }

    public function renderContent()
    {
        if (version_compare(Mongo::VERSION, '1.3.0', '>=')) {
            $stream = $this->data->getResource();
            while (!feof($stream)) {
                echo fread($stream, 8192);
            }
        } else {
            echo $this->data->getBytes();
        }
    }
}
