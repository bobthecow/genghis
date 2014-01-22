var gulp       = require('gulp');
var coffeelint = require('gulp-coffeelint');
var jshint     = require('gulp-jshint');
var chalk      = require('chalk');
var map        = require('map-stream');


// Lint coffeescript and js.
//
// Currently only lints the client code.
// TODO: do this with the server code too.
gulp.task('lint', function() {
  gulp.src('client/js/**/*.coffee')
    .pipe(coffeelint({
      max_line_length: {value: 120, level: 'warn'}
    }))
    .pipe(map(function (file, cb) {
      if (!file.coffeelint.success) {
        var filename = file.path.replace(file.cwd + '/', '');
        console.log(filename + ":\n");
        file.coffeelint.results.forEach(function (error) {
          var color = error.level == 'error' ? chalk.red : chalk.yellow;
          console.log(color('  ' + error.message));
          console.log(chalk.grey('  ' + filename + ':' + error.lineNumber + "\n"));
        });
      }
      cb(null, file);
    }));

  gulp.src(['gulpfile.js', 'tasks/**/*.js', 'client/js/**/*.js', '!client/js/modernizr.js'])
    .pipe(jshint({
      browser: true, // window, document, atob, etc.
      node:    true  // we're rockin' node-style with browserify.
    }))
    .pipe(map(function (file, cb) {
      if (!file.jshint.success) {
        var filename = file.path.replace(file.cwd + '/', '');
        console.log(filename + ":\n");
        file.jshint.results.forEach(function (result) {
          if (result.error) {
            console.log(chalk.red('  ' + result.error.reason));
            console.log(chalk.grey('  ' + filename + ':' + result.error.line + ':' + result.error.character + "\n"));
          }
        });
      }
      cb(null, file);
    }));
});
