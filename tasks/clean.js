var gulp  = require('gulp');
var clean = require('gulp-clean');

// Remove all compiled assets.
gulp.task('clean', function() {
  return gulp.src(['public', 'tmp'])
    .pipe(clean());
});

