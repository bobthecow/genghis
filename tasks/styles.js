var fs           = require('fs');
var path         = require('path');

var gulp         = require('gulp');
var autoprefixer = require('gulp-autoprefixer');
var bytediff     = require('gulp-bytediff');
var concat       = require('gulp-concat');
var csso         = require('gulp-csso');
var header       = require('gulp-header');
var less         = require('gulp-less');
var livereload   = require('gulp-livereload');
// var notify       = require('gulp-notify');
var rename       = require('gulp-rename');

var gutil        = require('gulp-util');
var log          = gutil.log;
var colors       = gutil.colors;

var datauri      = require('./datauri');

var server;

var HEADER = fs.readFileSync('server/templates/banner.tpl');
var HEADER_DATA = {
  version: fs.readFileSync('VERSION.txt')
};

// Compile and concatenate LESS (and other) stylesheets.
gulp.task('styles', function() {
  if (!server) throw new Error('Server not set.');

  log(colors.blue('Compiling stylesheets'));

  return gulp.src('client/css/style.less')
    .pipe(less({
      paths: [path.join(path.dirname(__dirname), 'assets', 'css')]
    }))

    // Normal
    .pipe(concat('style.css'))
    .pipe(header(HEADER, HEADER_DATA))
    .pipe(bytediff.start())
    .pipe(gulp.dest('public/css'))
    .pipe(livereload(server))
    //.pipe(notify('Stylesheet updated'))

    // Minified
    .pipe(rename({suffix: '.min'}))
    .pipe(datauri({
      base:   'client/css/',
      target: 'client/img/backgrounds/*.*'
    }))
    .pipe(autoprefixer())
    .pipe(csso())
    .pipe(header(HEADER, HEADER_DATA))
    .pipe(bytediff.stop())
    .pipe(gulp.dest('public/css'));
    //.pipe(notify('Minified stylesheet updated'));
});

module.exports = {withServer: function(lr) { server = lr; }};
