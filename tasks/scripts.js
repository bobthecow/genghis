var fs         = require('fs');
var path       = require('path');

var browserify = require('browserify');

var gulp       = require('gulp');
var buffer     = require('gulp-buffer');
var bytediff   = require('gulp-bytediff');
var header     = require('gulp-header');
var livereload = require('gulp-livereload');
// var notify     = require('gulp-notify');
var rename     = require('gulp-rename');
var uglify     = require('gulp-uglify');

var gutil      = require('gulp-util');
var log        = gutil.log;
var colors     = gutil.colors;

// TODO: replace this when upstream gets its act together.
var source     = require('./source');

var server;

var HEADER = fs.readFileSync('server/templates/banner.tpl');
var HEADER_DATA = {
  version: fs.readFileSync('VERSION.txt')
};

// Compile and minify JavaScript source.
gulp.task('scripts', function() {
  if (!server) throw new Error('Server not set.');

  log(colors.blue('Compiling scripts'));

  // Start with browserify...
  return browserify({
    debug:      true,
    extensions: ['.coffee']
  })
    .add('./client/js/script.js')
    .transform('browserify-hogan')
    .transform('coffeeify')
    .transform('debowerify')
    .transform('brfs')
    .bundle()

    // And now pass it off to gulp
    .pipe(source('client/js/script.js'))
    .pipe(buffer()) // this pipeline doesn't play nice with vinyl-source-stream

    // Normal
    .pipe(bytediff.start())
    .pipe(gulp.dest('public/js'))
    //.pipe(notify('Script updated'))
    .pipe(livereload(server))

    // Minified
    .pipe(rename({suffix: '.min'}))
    .pipe(uglify({
      output: {ascii_only: true}
    }))
    .pipe(header(HEADER, HEADER_DATA))
    .pipe(bytediff.stop())
    .pipe(gulp.dest('public/js'));
    //.pipe(notify('Minified script updated'));
});

module.exports = {withServer: function(lr) { server = lr; }};
