<?php

/**
 * Genghis Dev Server
 *
 * The single-file MongoDB admin app
 *
 * http://genghisapp.com
 *
 * @author Justin Hileman <justin@justinhileman.info>
 */
define('GENGHIS_VERSION', file_get_contents(dirname(__FILE__).'/VERSION'));

require dirname(__FILE__).'/server/php/Genghis/Autoloader.php';

Genghis_Autoloader::register();

$app = new Genghis_App(new Genghis_AssetLoader_Dev(dirname(__FILE__) . '/public', dirname(__FILE__) . '/public/templates'));
$app->run();
