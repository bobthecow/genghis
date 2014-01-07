'use strict';

var gulp       = require('gulp');
var stream     = require('event-stream');
var path       = require('path');
var map        = require('map-stream');
var chalk      = require('chalk');

var clean      = require('gulp-clean');
var concat     = require('gulp-concat');
var cssmin     = require('gulp-minify-css');
var header     = require('gulp-header');
var htmlmin    = require('gulp-htmlmin');
var jshint     = require('gulp-jshint');
var coffeelint = require('gulp-coffeelint');
var less       = require('gulp-less');
var spawn      = require('gulp-spawn');
var uglify     = require('gulp-uglify');
var browserify = require('gulp-browserify');


var VERSION = '3.0.0-dev';

var COFFEELINT_OPTS = {
  max_line_length: {
    name: "max_line_length",
    value: 120,
    level: "error",
    limitComments: true
  }
};

var JSHINT_OPTS = {
  browser: true, // window, document, atob, etc.
  node:    true  // since we're rockin' the node-style with browserify, we don't need to worry about this.
};


gulp.task('clean', function() {
  gulp.src(['public', 'tmp'])
    .pipe(clean());
});


gulp.task('scripts', function() {
  gulp.src('client/js/script.js')
    // Normal
    .pipe(browserify({
      transform: ['coffeeify', 'debowerify', 'brfs']
    }))
    .pipe(gulp.dest('public/js'))

    // Minified
    .pipe(uglify())
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
    .pipe(header({
      file:    'src/templates/banner.mustache',
      version: VERSION
    }))
    .pipe(gulp.dest('public/css'))

    // Minified
    .pipe(cssmin({
      keepSpecialComments: 0
    }))
    .pipe(header({
      file:    'src/templates/banner.mustache',
      version: VERSION
    }))
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

gulp.task('build', ['styles', 'scripts']);

gulp.task('default', function() {
  gulp.run(['clean', 'build']);

  gulp.watch('client/css/**/*.{less,css}', function() {
    gulp.run('styles');
  });

  gulp.watch('client/js/**/*.{js,coffee}', function() {
    gulp.run(['lint', 'scripts']);
  });
});
