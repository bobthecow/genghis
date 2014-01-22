var gulp = require('gulp');
var sloc = require('gulp-sloc');

// Misc code reporting.
gulp.task('report', function() {
  gulp.src(['client/js/**/*.{js,coffee}', 'server/php/**/*.php', 'server/rb/**.*.rb'])
    .pipe(sloc());
});
