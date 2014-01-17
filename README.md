[Genghis](http://genghisapp.com)
================================

The single-file MongoDB admin app, by [Justin Hileman](http://justinhileman.info).

[![Build Status](https://secure.travis-ci.org/bobthecow/genghis.png)](http://travis-ci.org/bobthecow/genghis) [![Dependency Status](https://gemnasium.com/bobthecow/genghis.png)](https://gemnasium.com/bobthecow/genghis)

[![Genghis](http://genghisapp.com/genghis.png)](http://genghisapp.com)

There are more ways to run Genghis than you can shake a stick at
----------------------------------------------------------------


### Standalone

If you installed Genghis as a Ruby gem, running Genghis standalone is easy:

```
$ genghisapp
```

Now that it's running, you can use `genghisapp --kill` to stop it.

**Windows users**: Due to [this bug](https://github.com/quirkey/vegas/issues/3) Genghis always runs in foreground mode.

If you didn't go the gem route, you can still run `genghis.rb` standalone:

```
$ ruby genghis.rb
```

`genghis.php` can also be run as a PHP 5.4 CLI SAPI standalone server:

```
$ php -S localhost:8000 genghis.php
```


### In your LAMP stack

Simply drop `genghis.php` in a web-accessible directory on a LAMP server. Don't forget `.htaccess` for pretty URLs!


### With nginx and PHP-fpm (and friends)

You'll need [some fancy config action](https://github.com/bobthecow/genghis/wiki), but it's fairly straightforward.


### In an existing Rack app

For a super basic Rack config, use a `config.ru` file like this:

```rb
require 'genghis'

run Genghis::Server
```

If you want to load Genghis on a subpath, possibly alongside other apps, it's easy to do with Rack's `URLMap`:

```rb
require 'genghis'

run Rack::URLMap.new \
  '/'        => Your::App.new,
  '/genghis' => Genghis::Server.new
```


### With Rails 3

You can even mount Genghis on a subpath in your existing Rails 3 app by adding `require 'genghis'` to the top of your
routes file (or in an initializer) and then adding this to `routes.rb`:

```rb
mount Genghis::Server.new, :at => '/genghis'
```



Genghis Dependencies
--------------------


### PHP

You will need at least PHP 5.2 and [the PECL MongoDB driver](http://www.mongodb.org/display/DOCS/PHP+Language+Center).


### Ruby

Genghis requires Ruby 1.8 or awesomer.

The easiest way to install Genghis and all dependencies is via RubyGems:

```
$ gem install genghisapp
```

Or you could check out a local copy of the Git repo and install dependencies via Bundler:

```
$ gem install bundler
$ bundle install
```



Configuration
-------------

Check [the Genghis wiki](https://github.com/bobthecow/genghis/wiki) for additional configuration information.



License
-------

 * Copyright 2011 [Justin Hileman](http://justinhileman.com)
 * Distributed under the [MIT License](http://creativecommons.org/licenses/MIT/)


### Genghis uses a number of amazing open source libraries, distributed under the following licenses

 * [Backbone.js][backbone]        — MIT License
 * [CodeMirror][codemirror]       — MIT-style License
 * [Esprima][esprima]             — "Simplified" BSD License (2-clause)
 * [Hogan.js][hogan]              — Apache License v2.0
 * [hoverIntent][hoverintent]     — MIT or GPLv2 License
 * [jQuery][jquery]               — MIT License
 * [KEYS.css][keyscss]            — MIT License
 * [Modernizr][modernizr]         — MIT or BSD (3-clause) License
 * [Mousetrap][mousetrap]         — Apache License v2.0
 * [TableSorter][tablesorter]     — MIT or GPLv2 License
 * [Twitter Bootstrap][bootstrap] — Apache License v2.0
 * [Underscore.js][underscore]    — MIT License

 [backbone]:          http://backbonejs.org
 [codemirror]:        http://codemirror.net
 [esprima]:           http://esprima.org
 [hogan]:             http://twitter.github.com/hogan.js/
 [hoverintent]:       http://cherne.net/brian/resources/jquery.hoverIntent.html
 [jquery]:            http://jquery.com
 [keyscss]:           http://michaelhue.com/keyscss
 [modernizr]:         http://modernizr.com
 [mousetrap]:         http://craig.is/killing/mice
 [tablesorter]:       http://tablesorter.com
 [bootstrap]:         http://twitter.github.com/bootstrap/
 [underscore]:        http://underscorejs.org
