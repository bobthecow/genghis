var gulp       = require('gulp');
var coffeelint = require('gulp-coffeelint');
var jshint     = require('gulp-jshint');
var map        = require('map-stream');

var gutil      = require('gulp-util');
var log        = gutil.log;
var colors     = gutil.colors;

var reportCoffee = function (file, cb) {
  if (!file.coffeelint.success) {
    var filename = file.path.replace(file.cwd + '/', '');
    console.log(filename + ":\n");
    file.coffeelint.results.forEach(function (error) {
      var color = error.level == 'error' ? colors.red : colors.yellow;
      console.log(color('  ' + error.message));
      console.log(colors.grey('  ' + filename + ':' + error.lineNumber + "\n"));
    });
  }
  cb(null, file);
};

var reportJS = function (file, cb) {
  if (!file.jshint.success) {
    var filename = file.path.replace(file.cwd + '/', '');
    console.log(filename + ":\n");
    file.jshint.results.forEach(function (result) {
      if (result.error) {
        console.log(colors.red('  ' + result.error.reason));
        console.log(colors.grey('  ' + filename + ':' + result.error.line + ':' + result.error.character + "\n"));
      }
    });
  }
  cb(null, file);
};

// Lint coffeescript and js.
//
// Currently only lints the client code.
// TODO: do this with the server code too.
gulp.task('lint', function() {
  log(colors.blue('Linting client code'));

  gulp.src(['client/js/**/*.coffee', '!client/js/json.coffee'])
    .pipe(coffeelint({
      max_line_length: {value: 120, level: 'warn'}
    }))
    .pipe(map(reportCoffee));

  gulp.src('client/js/json.coffee')
    .pipe(coffeelint({
      max_line_length: {level: 'ignore'}
    }))
    .pipe(map(reportCoffee));

  gulp.src(['gulpfile.js', 'tasks/**/*.js', 'client/js/**/*.js', '!client/js/modernizr.js', '!tasks/source.js'])
    .pipe(jshint({
      browser: true, // window, document, atob, etc.
      node:    true  // we're rockin' node-style with browserify.
    }))
    .pipe(map(reportJS));
});
