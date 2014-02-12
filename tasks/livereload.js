var gulp   = require('gulp');

var gutil  = require('gulp-util');
var log    = gutil.log;
var colors = gutil.colors;

var server;

// Start a LiveReload server instance.
gulp.task('livereload', function() {
  if (!server) throw new Error('Server not set.');

  log(colors.blue('Starting LiveReload server'));

  server.listen(35729, function(err) {
    if (err) log(colors.red(err));
  });
});

module.exports = {withServer: function(lr) { server = lr; }};
