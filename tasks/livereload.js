var gulp = require('gulp');
var server;

// Start a LiveReload server instance.
gulp.task('livereload', function() {
  if (!server) throw new Error('Server not set.');

  server.listen(35729, function(err) {
    if(err) return console.log(err);
  });
});

module.exports = {withServer: function(lr) { server = lr; }};
