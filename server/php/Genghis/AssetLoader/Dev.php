<?php

class Genghis_AssetLoader_Dev implements Genghis_AssetLoader
{
    private $baseDir;
    private $templateDir;

    public function __construct($baseDir, $templateDir)
    {
        $this->baseDir     = $baseDir;
        $this->templateDir = $templateDir;
    }

    public function load($name)
    {
        $fileName = $this->fileName($name);
        $data     = file_get_contents($fileName);

        return new Genghis_AssetResponse($name, $data, array(
            'Last-Modified' => gmdate('D, d M Y H:i:s', filemtime($fileName)) . ' GMT',
        ));
    }

    public function loadTemplate($name)
    {
        $fileName = sprintf('%s/%s', $this->templateDir, $name);
        if (!file_exists($fileName)) {
            throw new InvalidArgumentException(sprintf("Unknown template: '%s'", $name));
        }

        return file_get_contents($fileName);
    }

    private function fileName($name)
    {
        $fileName = sprintf('%s/%s', $this->baseDir, $name);
        if (!file_exists($fileName)) {
            throw new InvalidArgumentException(sprintf("Unknown asset: '%s'", $name));
        }

        return $fileName;
    }

    private function initAssets()
    {
        if (empty($this->assets)) {
            $data = file_get_contents($this->file, false, null, $this->offset);
            foreach (preg_split("/^@@(?=[\w\d\.]+( [\w\d\.]+)?$)/m", $data, -1) as $asset) {
                if (trim($asset)) {
                    list($line, $content)    = explode("\n", $asset, 2);
                    list($name, $etag)       = explode(' ',  $line,  2);
                    $this->assets[$name]     = trim($content);
                    $this->assetEtags[$name] = $etag;
                }
            }
        }
    }
}
