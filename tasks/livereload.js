var gulp       = require('gulp');
var livereload = require('gulp-livereload');
var es         = require('event-stream');

var gutil      = require('gulp-util');
var log        = gutil.log;
var colors     = gutil.colors;

var server;

// If the server has been started, pass changes through
var reload = function() {
  return es.map(function(file, cb) {
    if (typeof server !== 'undefined') {
      server.changed(file.path);
    }
    cb(null, file);
  });
};

// Start a LiveReload server instance.
reload.start = function() {
  log(colors.blue('Starting LiveReload server'));
  server = livereload();
};

module.exports = reload;
