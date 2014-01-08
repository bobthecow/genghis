'use strict';

var gulp    = require('gulp');
var t       = require('gulp-load-tasks')();
var chalk   = require('chalk');
var lr      = require('tiny-lr');
var map     = require('map-stream');
var path    = require('path');
var stream  = require('event-stream');
var datauri = require('datauri');

// TODO: switch back to the original once my PR is released.
var hoganify   = require('./tasks/browserify-hogan');

var server = lr();

var VERSION = '3.0.0-dev';

var COFFEELINT_OPTS = {
  max_line_length: {value: 120}
};

var JSHINT_OPTS = {
  browser: true, // window, document, atob, etc.
  node:    true  // since we're rockin' the node-style with browserify, we don't need to worry about this.
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
  gulp.src(['public'])
    .pipe(t.clean());
});


// Compile and minify JavaScript source.
gulp.task('scripts', function() {
  gulp.src('client/js/script.js')
    // Normal
    .pipe(t.browserify({
      transform: [hoganify, 'coffeeify', 'debowerify', 'brfs'],
      debug: true
    }))
    .pipe(t.header(HEADER_OPTS))
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

  stream.concat(vendors, backgrounds, genghis)
    // Normal
    .pipe(t.concat('style.css'))
    .pipe(t.header(HEADER_OPTS))
    .pipe(t.bytediff.start())
    .pipe(gulp.dest('public/css'))
    .pipe(t.livereload(server))

    // Minified
    .pipe(t.rename({suffix: '.min'}))
    .pipe(t.autoprefixer())
    .pipe(t.csso())
    .pipe(t.header(HEADER_OPTS))
    .pipe(t.bytediff.stop())
    .pipe(gulp.dest('public/css'));
});


// Compile page templates.
gulp.task('templates', function() {
  gulp.src('server/templates/{index,error}.mustache.tpl')
    .pipe(t.rename({ext: '.mustache'}))
    .pipe(t.template({
      favicon:  '{{ base_url }}/img/favicon.png',
      style:    '{{ base_url }}/css/style.css',
      script:   '{{ base_url }}/js/script.js',
      keyboard: '{{ base_url }}/img/keyboard.png'
    }))
    .pipe(gulp.dest('public/templates'));

  gulp.src('server/templates/{index,error}.mustache.tpl')
    .pipe(t.rename({ext: '.min.mustache'}))
    .pipe(t.template({
      favicon:  datauri('client/img/favicon.png'),
      style:    '{{ base_url }}/css/style.min.css',
      script:   '{{ base_url }}/js/script.min.js',
      keyboard: datauri('client/img/keyboard.png')
    }))
    .pipe(t.htmlmin(HTMLMIN_OPTS))
    .pipe(gulp.dest('public/templates'));
});


// Copy static assets over to public directory
gulp.task('copy', function() {
  gulp.src('client/img/**')
    .pipe(gulp.dest('public/img'));
});


// Lint coffeescript and js.
//
// Currently only lints the client code.
// TODO: do this with the server code too.
gulp.task('lint', function() {
  gulp.src(['client/js/**/*.coffee'])
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

  gulp.src(['gulpfile.js', 'client/js/**/*.js', '!client/js/modernizr.js'])
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
gulp.task('lr-server', function() {
  server.listen(35729, function(err) {
    if(err) return console.log(err);
  });
});


// Build Genghis.
gulp.task('build', ['styles', 'scripts', 'templates', 'copy']);


gulp.task('default', function() {
  gulp.run('lr-server', 'clean', 'build');

  gulp.watch('client/css/**/*.{less,css}', function() {
    gulp.run('styles');
  });

  gulp.watch('client/js/**/*.{js,coffee}', function() {
    gulp.run(['lint', 'scripts']);
  });

  gulp.watch('client/img/**.*', function() {
    gulp.run(['copy']);
  });

  gulp.watch('server/templates/{index,error}.mustache.tpl', function() {
    gulp.run('templates');
  });
});
