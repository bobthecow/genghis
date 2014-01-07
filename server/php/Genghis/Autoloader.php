<?php

class Genghis_Autoloader
{
    private $baseDir;

    public function __construct($baseDir = null)
    {
        if ($baseDir === null) {
            $this->baseDir = dirname(__FILE__).'/..';
        } else {
            $this->baseDir = rtrim($baseDir, '/');
        }
    }

    public static function register($baseDir = null)
    {
        $loader = new self($baseDir);
        spl_autoload_register(array($loader, 'autoload'));

        return $loader;
    }

    public function autoload($class)
    {
        if ($class[0] === '\\') {
            $class = substr($class, 1);
        }

        if (strpos($class, 'Genghis') !== 0) {
            return;
        }

        $file = sprintf('%s/%s.php', $this->baseDir, str_replace('_', '/', $class));
        if (is_file($file)) {
            require $file;
        }
    }
}
