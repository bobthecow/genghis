var gulp   = require('gulp');
var clean  = require('gulp-clean');

var gutil  = require('gulp-util');
var log    = gutil.log;
var colors = gutil.colors;

// Remove all compiled assets.
gulp.task('clean', function() {
  log(colors.blue('Cleaning previous builds'));

  return gulp.src(['public', 'tmp'])
    .pipe(clean());
});

