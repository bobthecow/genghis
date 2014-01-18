# Contributions welcome!

First, I'd like to apologize to the PHP devs for making you mess with Ruby and/or Node.js. But it's for the best.


## Development requirements

We'll start by cloning the repository and starting a feature branch:

```sh
git clone https://github.com/bobthecow/genghis
cd genghis
git checkout develop
git checkout -b feature/my-alsome-feature
```

In order to build assets (including the entire client-side app) you'll need Node.js. So go get that in a way
appropriate to your operating system. Then install dependencies.

```sh
npm install -g gulp
npm install
```

In order to run the test suite, you'll need Ruby, too. Ruby 1.9.x or 2.x would be best. After you've got Ruby, install
those dependencies:

```sh
gem install bundler
bundle install
```


## Running Genghis

Two development apps are shipped with Genghis: `genghis-dev.rb` and `genghis-dev.php`. They're much awesomer: they have
unminified assets, and those assets use source maps, so you can actually tell what code you're hacking on. Unlike
`genghis.rb` and `genghis.php`, these dev apps have external dependencies, and can't just be dropped on a server. But
they can be used from where they sit.

First, build the assets they expect:

```sh
gulp styles scripts copy templates
```

That will create a `public` directory with all the assets that `genghis-dev.*` need to run. Now start up your dev
app of choice:

```sh
php -S localhost:4567 genghis-dev.php
```

…or

```sh
ruby genghis-dev.rb
```

Then visit [http://localhost:4567](http://localhost:4567) in your browser and start playing.

For added dev awesomeness, you can run a gulp task called `dev`, which watches source files for changes and
automatically rebuilds them. As a bonus, it sets up LiveReload as well. So install the Chrome or Safari browser
plugins for great justice.

```sh
gulp dev
```


## Building Genghis

Genghis is... a bit weird.

 * Genghis is built with a JavaScript build system called [gulp](http://gulpjs.com). To build it, run `gulp` from the
   project directory.
 * The development apps, `genghis-dev.rb` and `genghis-dev.php` don't need to be built before using them. They include
   source files out of the `server/*` directory like sane, normal, webapps. But they do require client-side assets to
   be generated.
 * To build client-side assets, run `gulp styles scripts copy templates`.
 * The two production app files, `genghis.rb` and `genghis.php`, should never be edited by hand. In fact, there's a
   non-zero chance that editing them will crash your IDE. They can be built by runing `gulp rebuild`.
 * Go ahead and skip committing the updated `genghis.rb` and `genghis.php`… that's just asking for a merge conflict,
   and we'll recompile them before cutting a release anyway.


## Running the API test suite

If you're changing the API, you'll need to ensure that the API test suite passes. If you're adding a new feature or
fixing a bug, you should add corresponding tests as well.

The test suite runs on four different backends: `rb`, `rb_dev`, `php`, and `php_dev`. To run any of the tests,
you'll need a Mongo instance running on `localhost`.

To test the PHP backends, you'll need PHP 5.4+, as well as the Mongo driver from PECL.

```sh
rspec
```

If you don't have PHP, or you just want to test one backend, you can restrict the test suite by setting a
GENGHIS_BACKEND environment variable:

```sh
GENGHIS_BACKEND=rb rspec
GENGHIS_BACKEND=rb_dev rspec
GENGHIS_BACKEND=php rspec
GENGHIS_BACKEND=php_dev rspec
```


## Opening a pull request

You can do some things to increase the chance that your pull request is accepted the first time:

 * Open all pull requests against the `develop` branch.
 * Submit one pull request per fix or feature.
 * To help with that, do your work in a feature branch (e.g. `feature/my-alsome-feature`).
 * Follow the conventions you see used in the project. This is especially important when switching between languages,
   since Genghis is essentially a Ruby server, an PHP server, and a JavaScript (and CoffeeScript) client. Make your
   code look like the code around it.
 * (PHP code follows PSR-1/2. Ruby code follows the Ruby Style Guide, via RuboCop, with the config at `.rubocop.yml`)
 * Write API tests that fail without your code, and pass with it.
 * Don't bump version numbers. Those will be updated — per [semver](http://semver.org) — once your change is merged into
   `master`.
 * Don't commit `genghis.rb` or `genghis.php`. They're merge-conflictastic. We'll recompile them before merging your
   updates into `master`.
 * Update any documentation: docblocks, README, etc.
 * ... Don't update the wiki until your change is merged and released, but make a note in your pull request so we don't
   forget.
