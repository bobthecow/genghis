'use strict';

var _       = require('lodash');
var fs      = require('fs');
var gulp    = require('gulp');
var t       = require('gulp-load-tasks')();
var gutil   = require('gulp-util');
var chalk   = require('chalk');
// var chalk   = gutil.color;
var lr      = require('tiny-lr');
var map     = require('map-stream');
var path    = require('path');
var stream  = require('event-stream');
var datauri = require('datauri');
var toDatauri = require('./tasks/datauri');


// TODO: switch back to the originals once my PRs are released.
var hoganify = require('./tasks/browserify-hogan');
var header   = require('./tasks/header');

var server = lr();


var VERSION = fs.readFileSync('VERSION.txt');

var COFFEELINT_OPTS = {
  max_line_length: {value: 120}
};

var JSHINT_OPTS = {
  browser: true, // window, document, atob, etc.
  node:    true  // we're rockin' node-style with browserify.
};

var HEADER_OPTS = {
  file:    'server/templates/banner.mustache',
  version: VERSION
};

var HTMLMIN_OPTS = {
  removeComments:            true,
  collapseWhitespace:        true,
  collapseBooleanAttributes: true,
  removeRedundantAttributes: true,
  removeEmptyAttributes:     true
};


// Remove all compiled assets.
gulp.task('clean', function() {
  return gulp.src(['public', 'tmp'])
    .pipe(t.clean());
});


// Compile and minify JavaScript source.
gulp.task('scripts', function() {
  return gulp.src('client/js/script.js')
    // Normal
    .pipe(t.browserify({
      transform: [hoganify, 'coffeeify', 'debowerify', 'brfs'],
      debug: true
    }))
    .pipe(t.bytediff.start())
    .pipe(gulp.dest('public/js'))
    .pipe(t.livereload(server))

    // Minified
    .pipe(t.rename({suffix: '.min'}))
    .pipe(t.uglify({
      output: {ascii_only: true}
    }))
    .pipe(t.header(HEADER_OPTS))
    .pipe(t.bytediff.stop())
    .pipe(gulp.dest('public/js'));
});


// Compile and concatenate LESS (and other) stylesheets.
gulp.task('styles', function() {

  // vendor styles
  var vendors = gulp.src([
    'client/vendor/codemirror/lib/codemirror.css',
    'client/vendor/keyscss/keys.css'
  ]);

  // background images (coming soon: with data uris!)
  var backgrounds = gulp.src('client/css/backgrounds.css');

  // genghis styles
  var genghis = gulp.src('client/css/style.less')
    .pipe(t.less({
      paths: [path.join(__dirname, 'assets', 'css')]
    }));

  return stream.concat(vendors, backgrounds, genghis)
    // Normal
    .pipe(t.concat('style.css'))
    .pipe(t.header(HEADER_OPTS))
    .pipe(t.bytediff.start())
    .pipe(gulp.dest('public/css'))
    .pipe(t.livereload(server))

    // Minified
    .pipe(t.rename({suffix: '.min'}))
    .pipe(toDatauri({
      base:   'client/css/',
      target: 'client/img/backgrounds/*.*'
    }))
    .pipe(t.autoprefixer())
    .pipe(t.csso())
    .pipe(t.header(HEADER_OPTS))
    .pipe(t.bytediff.stop())
    .pipe(gulp.dest('public/css'));
});


// Compile page templates.
gulp.task('templates', function() {
  var dev = gulp.src('server/templates/{index,error}.mustache.tpl')
    .pipe(t.rename({ext: '.mustache'}))
    .pipe(t.template({
      favicon: '{{ base_url }}/img/favicon.png',
    }))
    .pipe(gulp.dest('public/templates'))
    .pipe(t.livereload(server));

  var dist = gulp.src('server/templates/{index,error}.mustache.tpl')
    .pipe(t.rename({ext: '.min.mustache'}))
    .pipe(t.template({
      favicon: datauri('client/img/favicon.png'),
    }))
    .pipe(t.bytediff.start())
    .pipe(t.htmlmin(HTMLMIN_OPTS))
    .pipe(t.bytediff.stop())
    .pipe(gulp.dest('public/templates'));

  return stream.concat(dev, dist);
});


// Copy static assets over to public directory
gulp.task('copy', function() {
  return gulp.src('client/img/**')
    .pipe(gulp.dest('public/img'))
    .pipe(t.livereload(server));
});


// Lint coffeescript and js.
//
// Currently only lints the client code.
// TODO: do this with the server code too.
gulp.task('lint', function() {
  gulp.src('client/js/**/*.coffee')
    .pipe(t.coffeelint(COFFEELINT_OPTS))
    .pipe(map(function (file, cb) {
      if (!file.coffeelint.success) {
        var filename = file.path.replace(file.cwd + '/', '');
        console.log(filename + ":\n");
        file.coffeelint.results.forEach(function (error) {
          console.log(chalk.red('  ' + error.message));
          console.log(chalk.grey('  ' + filename + ':' + error.lineNumber + "\n"));
        });
      }
      cb(null, file);
    }));

  gulp.src(['gulpfile.js', 'tasks/**/*.js', 'client/js/**/*.js', '!client/js/modernizr.js', '!tasks/browserify-hogan.js'])
    .pipe(t.jshint(JSHINT_OPTS))
    .pipe(map(function (file, cb) {
      if (!file.jshint.success) {
        var filename = file.path.replace(file.cwd + '/', '');
        console.log(filename + ":\n");
        file.jshint.results.forEach(function (result) {
          if (result.error) {
            console.log(chalk.red('  ' + result.error.reason));
            console.log(chalk.grey('  ' + filename + ':' + result.error.line + ':' + result.error.character + "\n"));
          }
        });
      }
      cb(null, file);
    }));
});


// Start a LiveReload server instance.
gulp.task('livereload', function() {
  server.listen(35729, function(err) {
    if(err) return console.log(err);
  });
});


// Misc code reporting.
gulp.task('report', function() {
  gulp.src(['client/js/**/*.{js,coffee}', 'server/php/**/*.php', 'server/rb/**.*.rb'])
    .pipe(t.sloc());
});


// Internal builds for distribution...
gulp.task('build:assets', ['styles', 'scripts', 'templates', 'copy'], function() {
  return gulp.src([
    'public/js/script.min.js',
    'public/css/style.min.css',
    'public/templates/index.min.mustache',
    'public/templates/error.min.mustache'
  ])
    .pipe(header(function(file) {
      return "\n@@ " + file.path.replace(/^.*?public\/(templates\/)?|/, '').replace('.min.', '.') + "\n";
    }))
    .pipe(t.concat('assets.txt'))
    .pipe(gulp.dest('tmp'));
});

gulp.task('build:php:lib', function() {
  return gulp.src(['server/php/**/*.php', '!server/php/Genghis/AssetLoader/Dev.php'])
    .pipe(t.spawn({cmd: 'php', args: ['-w']}))
    .pipe(t.replace(/^(<\?php\n\s*|\s*$)/g, ''))
    .pipe(t.concat('lib.php'))
    .pipe(gulp.dest('tmp'));
});

gulp.task('build:php', function() {
  gulp.src('server/templates/genghis.php.tpl')
    .pipe(t.template({
      version:  VERSION,
      includes: fs.readFileSync('tmp/lib.php'),
      assets:   fs.readFileSync('tmp/assets.txt')
    }))
    .pipe(t.rename('genghis.php'))
    .pipe(gulp.dest('.'));
});

gulp.task('build:rb:lib', function() {
  return gulp.src([
    'server/rb/genghis/json.rb',
    'server/rb/genghis/errors.rb',
    'server/rb/genghis/models/**/*',
    'server/rb/genghis/helpers.rb',
    'server/rb/genghis/server.rb'
  ])
    .pipe(t.concat('lib.rb'))
    .pipe(gulp.dest('tmp'));
});

gulp.task('build:rb', function() {
  gulp.src('server/templates/genghis.rb.tpl')
    .pipe(t.template({
      version:  VERSION,
      includes: fs.readFileSync('tmp/lib.rb'),
      assets:   fs.readFileSync('tmp/assets.txt')
    }))
    .pipe(t.rename('genghis.rb'))
    .pipe(gulp.dest('.'));
});


// Build Genghis.
gulp.task('build', ['build:assets', 'build:rb:lib', 'build:php:lib'], function() {
  gulp.run('build:rb', 'build:php');
});


// Rebuild Genghis.
gulp.task('rebuild', ['clean'], function() {
  gulp.run('build');
});


// For the developments. Livereload, plus building dev versions of stuff.
gulp.task('dev', ['clean'], function() {
  gulp.run('livereload', 'lint', 'styles', 'scripts', 'copy', 'templates');

  gulp.watch('client/css/**/*.{less,css}', function() {
    gulp.run('styles');
  });

  gulp.watch(['client/js/**/*.{js,coffee}', 'client/templates/**/*.mustache'], function() {
    gulp.run(['lint', 'scripts']);
  });

  gulp.watch('client/img/**.*', function() {
    gulp.run(['copy']);
  });

  gulp.watch('server/templates/{index,error}.mustache.tpl', function() {
    gulp.run('templates');
  });
});


// By default, build all the things!
gulp.task('default', ['rebuild']);
