<?php

/**
 * Genghis v<%= version %>
 *
 * The single-file MongoDB admin app
 *
 * http://genghisapp.com
 *
 * @author Justin Hileman <justin@justinhileman.info>
 */
define('GENGHIS_VERSION', '<%= version %>');

<%= includes %>

$app = new Genghis_App(new Genghis_AssetLoader_Inline(__FILE__, __COMPILER_HALT_OFFSET__));
$app->run();

__halt_compiler();

<%= assets %>
