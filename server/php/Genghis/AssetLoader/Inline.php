<?php

class Genghis_AssetLoader_Inline implements Genghis_AssetLoader
{
    private $file;
    private $offset;
    private $assets     = array();
    private $assetEtags = array();

    public function __construct($file, $offset)
    {
        $this->file   = $file;
        $this->offset = $offset;
    }

    public function load($name)
    {
        $data = $this->loadRaw($name);

        return new Genghis_AssetResponse($name, $data, array(
            'Last-Modified' => gmdate('D, d M Y H:i:s', filemtime($this->file)) . ' GMT',
            'Etag'          => sprintf('"%s"', $this->assetEtags[$name]),
        ));
    }

    public function loadTemplate($name)
    {
        return $this->loadRaw($name);
    }

    private function loadRaw($name)
    {
        $this->initAssets();

        if (!isset($this->assets[$name])) {
            throw new InvalidArgumentException(sprintf("Unknown asset: '%s'", $name));
        }

        return $this->assets[$name];
    }

    private function initAssets()
    {
        if (empty($this->assets)) {
            $data = file_get_contents($this->file, false, null, $this->offset);
            foreach (preg_split("/^@@ (?=[\/\w\d\.]+$)/m", $data, -1) as $asset) {
                if (trim($asset)) {
                    list($line, $content) = explode("\n", $asset, 2);

                    $name    = trim($line);
                    $content = trim($content);
                    $etag    = md5($content);

                    $this->assets[$name]     = $content;
                    $this->assetEtags[$name] = $etag;
                }
            }
        }
    }
}
