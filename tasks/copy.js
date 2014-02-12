var gulp       = require('gulp');
// var notify     = require('gulp-notify');

var gutil      = require('gulp-util');
var log        = gutil.log;
var colors     = gutil.colors;

var livereload = require('./livereload');

// Copy static assets over to public directory
gulp.task('copy', function() {
  log(colors.blue('Copying static assets'));

  return gulp.src('client/img/**')
    .pipe(gulp.dest('public/img'))
    .pipe(livereload());
    // .pipe(notify({
    //   message: 'Images updated',
    //   onLast:  true
    // }));
});
