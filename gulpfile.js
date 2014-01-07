
var gulp       = require('gulp');
var stream     = require('event-stream');
var path       = require('path');
var map        = require('map-stream');
var chalk      = require('chalk');

var clean      = require('gulp-clean');
var concat     = require('gulp-concat');
var cssmin     = require('gulp-minify-css');
var header     = require('gulp-header');
var htmlmin    = require('gulp-htmlmin');
var jshint     = require('gulp-jshint');
var coffeelint = require('gulp-coffeelint');
var less       = require('gulp-less');
var spawn      = require('gulp-spawn');
var uglify     = require('gulp-uglify');
var browserify = require('gulp-browserify');


var VERSION = '3.0.0-dev';

var rename = function(newName) {
  return map(function(file, cb) {
    if (typeof newName === 'function') {
      newName = newName(file.path.replace(file.base, ''), file);
    }
    file.path = path.join(file.base, newName);
    cb(null, file);
  });
};

var addMinExt = rename(function(fileName) {
  return fileName.replace(/\.([^\.]+)$/, '.min.$1');
});

gulp.task('clean', function() {
  gulp.src(['public'])
    .pipe(clean());
});


gulp.task('script', function() {
  gulp.src('assets/js/genghis/util.js')
    // Normal
    .pipe(browserify({
      transform: ['debowerify', 'coffeeify', 'brfs'],
      debug: true
    }))
    .pipe(gulp.dest('public/js'))

    // Minified
    .pipe(addMinExt)
      .pipe(uglify())
      .pipe(gulp.dest('public/js'));
});


gulp.task('style', function() {

  // vendor styles
  var vendors = gulp.src([
      'assets/vendor/codemirror/lib/codemirror.css',
      'assets/vendor/keyscss/keys.css'
    ]);

  // background images (coming soon: with data uris!)
  var backgrounds = gulp.src('assets/css/backgrounds.css');

  // genghis styles
  var genghis = gulp.src('assets/css/style.less')
    .pipe(less({
      paths: [path.join(__dirname, 'assets', 'css')]
    }));

  stream.concat(vendors, backgrounds, genghis)
    // Normal
    .pipe(concat('style.css'))
      .pipe(header({
        file:    'src/templates/banner.mustache',
        version: VERSION
      }))
      .pipe(gulp.dest('public'))

    // Minified
    .pipe(addMinExt)
      .pipe(cssmin({
        keepSpecialComments: 0
      }))
      .pipe(header({
        file:    'src/templates/banner.mustache',
        version: VERSION
      }))
      .pipe(gulp.dest('public'));
});


gulp.task('lint', function() {
  gulp.src(['assets/js/**/*.coffee'])
    .pipe(coffeelint())
    .pipe(map(function (file, cb) {
      if (!file.coffeelint.success) {
        var filename = file.path.replace(file.cwd + '/', '');
        console.log(filename + ":\n");
        file.coffeelint.results.forEach(function (error) {
          console.log(chalk.red('  ' + error.message));
          console.log(chalk.grey('  ' + filename + ':' + error.lineNumber + "\n"));
        });
      }
      cb(null, file);
    }));

  gulp.src(['gulpfile.js', 'assets/js/**/*.js'])
    .pipe(jshint())
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

gulp.task('default', ['clean', 'style', 'script']);
