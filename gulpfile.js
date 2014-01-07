'use strict';

var gulp       = require('gulp');
var chalk      = require('chalk');
var lr         = require('tiny-lr');
var map        = require('map-stream');
var path       = require('path');
var stream     = require('event-stream');

var browserify = require('gulp-browserify');
var clean      = require('gulp-clean');
var coffeelint = require('gulp-coffeelint');
var concat     = require('gulp-concat');
var cssmin     = require('gulp-minify-css');
var header     = require('gulp-header');
var htmlmin    = require('gulp-htmlmin');
var jshint     = require('gulp-jshint');
var less       = require('gulp-less');
var refresh    = require('gulp-livereload');
var spawn      = require('gulp-spawn');
var uglify     = require('gulp-uglify');

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


gulp.task('clean', function() {
  gulp.src(['public', 'tmp'])
    .pipe(clean());
});


gulp.task('scripts', function() {
  gulp.src('client/js/script.js')
    // Normal
    .pipe(browserify({
      transform: ['browserify-hogan', 'coffeeify', 'debowerify', 'brfs'],
      debug: true
    }))
    .pipe(header(HEADER_OPTS))
    .pipe(gulp.dest('public/js'))
    .pipe(refresh(server))

    // Minified
    .pipe(uglify({
      output: {ascii_only: true}
    }))
    .pipe(header(HEADER_OPTS))
    .pipe(gulp.dest('tmp'));
});


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
    .pipe(less({
      paths: [path.join(__dirname, 'assets', 'css')]
    }));

  stream.concat(vendors, backgrounds, genghis)
    // Normal
    .pipe(concat('style.css'))
    .pipe(header(HEADER_OPTS))
    .pipe(gulp.dest('public/css'))
    .pipe(refresh(server))

    // Minified
    .pipe(cssmin({
      keepSpecialComments: 0
    }))
    .pipe(header(HEADER_OPTS))
    .pipe(gulp.dest('tmp'));
});


gulp.task('lint', function() {
  gulp.src(['client/js/**/*.coffee'])
    .pipe(coffeelint(COFFEELINT_OPTS))
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
    .pipe(jshint(JSHINT_OPTS))
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


gulp.task('lr-server', function() {
  server.listen(35729, function(err) {
    if(err) return console.log(err);
  });
});


gulp.task('build', ['styles', 'scripts']);


gulp.task('default', function() {
  gulp.run('lr-server', 'clean', 'build');

  gulp.watch('client/css/**/*.{less,css}', function() {
    gulp.run('styles');
  });

  gulp.watch('client/js/**/*.{js,coffee}', function() {
    gulp.run(['lint', 'scripts']);
  });
});
