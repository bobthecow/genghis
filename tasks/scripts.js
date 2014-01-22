var fs         = require('fs');

var gulp       = require('gulp');
var browserify = require('gulp-browserify');
var bytediff   = require('gulp-bytediff');
var header     = require('gulp-header');
var livereload = require('gulp-livereload');
var notify     = require('gulp-notify');
var rename     = require('gulp-rename');
var uglify     = require('gulp-uglify');

var server;

var HEADER = fs.readFileSync('server/templates/banner.tpl');
var HEADER_DATA = {
  version: fs.readFileSync('VERSION.txt')
};

// Compile and minify JavaScript source.
gulp.task('scripts', function() {
  if (!server) throw new Error('Server not set.');

  return gulp.src('client/js/script.js')
    // Normal
    .pipe(browserify({
      transform: ['browserify-hogan', 'coffeeify', 'debowerify', 'brfs'],
      debug: true
    }))
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
