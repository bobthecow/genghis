var gulp       = require('gulp');
var livereload = require('gulp-livereload');
// var notify     = require('gulp-notify');

var server;

// Copy static assets over to public directory
gulp.task('copy', function() {
  return gulp.src('client/img/**')
    .pipe(gulp.dest('public/img'))
    .pipe(livereload(server))
    // .pipe(notify({
    //   message: 'Images updated',
    //   onLast:  true
    // }));
});

module.exports = {withServer: function(lr) { server = lr; }};
