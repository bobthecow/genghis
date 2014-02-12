var gulp   = require('gulp');

var gutil  = require('gulp-util');
var colors = gutil.colors;

// For the developments. Livereload, plus building dev versions of stuff.
gulp.task('dev', function() {
  gulp.run('livereload', 'lint', 'styles', 'scripts', 'copy', 'templates');

  var log = function(e) {
    var path = e.path.replace(__dirname + '/', '');
    gutil.log(colors.grey('File ' + path + ' was ' + e.type + ', running tasks...'));
  };

  gulp.watch('client/css/**/*.{less,css}', function(event) {
    log(event);
    gulp.run('styles');
  });

  gulp.watch(['client/js/**/*.{js,coffee}', 'client/templates/**/*.mustache'], function(event) {
    log(event);
    gulp.run(['lint', 'scripts']);
  });

  gulp.watch('client/img/**.*', function(event) {
    log(event);
    gulp.run(['copy']);
  });

  gulp.watch('server/templates/{index,error}.mustache.tpl', function(event) {
    log(event);
    gulp.run('templates');
  });
});
