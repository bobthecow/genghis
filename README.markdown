Genghis
=======

A single-file MongoDB admin app by Justin Hileman.

http://genghisapp.com


There are more ways to run Genghis than you can shake a stick at
----------------------------------------------------------------

 * Drop `genghis.php` in a web-accessible directory on a LAMP server. Don't forget `.htaccess` for perty URLs!
 * Run `genghis.php` on your nginx server [with some fancy config action](https://github.com/bobthecow/genghis/wiki).
 * Run `genghis.php` as a PHP 5.4 CLI SAPI standalone server: `php -S localhost:8000 genghis.php`.
 * Run `genghis.rb` directly: `ruby genghis.rb`.
 * Or a different way: `bin/genghisapp`.
 * In fact, if you installed the `genghisapp` Ruby gem, just run `genghisapp`.
 * Rack it up: `rackup -p 1234 genghis.rb`.
 * Or add `genghis.rb` to your Rack mount and run it inside another application.
 * ...
 * The possibilities are nearly endless!



Requirements
------------

 * `genghis.php` requires [the PECL MongoDB driver](http://www.mongodb.org/display/DOCS/PHP+Language+Center).

 * `genghis.rb` requires a handful of gems: `sinatra`, `sinatra-contrib`, `sinatra-mustache`, `mongo` and `json`. The
   easiest way to get them all is `gem install genghisapp`. As a bonus, this gives you a `genghisapp` binary to run.


Configuration
-------------

Check [the Genghis wiki](https://github.com/bobthecow/genghis/wiki) for additional configuration information.


License
-------

 * Copyright 2011 [Justin Hileman](http://justinhileman.com)
 * Distributed under the [MIT License](http://creativecommons.org/licenses/MIT/)


### Genghis uses a number of amazing open source libraries, distributed under the following licenses

 * [Apprise][apprise]                     — MIT License
 * [Apprise Bootstrap][apprise-bootstrap] — Apache License v2.0
 * [Backbone.js][backbone]                — MIT License
 * [CodeMirror][codemirror]               — MIT-style License
 * [Esprima][esprima]                     — "Simplified" BSD License (2-clause)
 * [Hogan.js][hogan]                      — Apache License v2.0
 * [hoverIntent][hoverintent]             — MIT or GPLv2 License
 * [jQuery][jquery]                       — MIT License
 * [jQuery Hotkeys][hotkeys]              — MIT or GPLv2 License
 * [KEYS.css][keyscss]                    — MIT License
 * [Modernizr][modernizr]                 — MIT or BSD (3-clause) License
 * [TableSorter][tablesorter]             — MIT or GPLv2 License
 * [Twitter Bootstrap][bootstrap]         — Apache License v2.0
 * [Underscore.js][underscore]            — MIT License

 [apprise]:           http://thrivingkings.com/apprise
 [apprise-bootstrap]: https://github.com/bobthecow/apprise-bootstrap
 [backbone]:          http://backbonejs.org
 [codemirror]:        http://codemirror.net
 [esprima]:           http://esprima.org
 [hogan]:             http://twitter.github.com/hogan.js/
 [hoverintent]:       http://cherne.net/brian/resources/jquery.hoverIntent.html
 [jquery]:            http://jquery.com
 [hotkeys]:           https://github.com/jeresig/jquery.hotkeys
 [keyscss]:           http://michaelhue.com/keyscss
 [modernizr]:         http://modernizr.com
 [tablesorter]:       http://tablesorter.com
 [bootstrap]:         http://twitter.github.com/bootstrap/
 [underscore]:        http://underscorejs.org
