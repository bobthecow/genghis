var path       = require('path');
var gulp       = require('gulp');

var gutil      = require('gulp-util');
var log        = gutil.log;
var colors     = gutil.colors;

var livereload = require('./livereload');

var STYLES    = ['client/css/**/*.{less,css}', 'server/templates/banner.tpl'];
var SCRIPTS   = ['client/js/**/*.{js,coffee}', 'client/templates/**/*.mustache', 'server/templates/banner.tpl'];
var IMAGES    = ['client/img/**/*.*'];
var TEMPLATES = ['server/templates/{index,error}.mustache.tpl', 'client/img/favicon.png'];

var logChange = function(e) {
  var name = e.path.replace(path.dirname(__dirname) + '/', '');
  log(colors.grey('File ' + name + ' was ' + e.type + ', running tasks…'));
};

var watch = function() {
  livereload.start();

  log(colors.blue('Watching for changes'));

  gulp.watch(STYLES, ['styles'])
    .on('change', logChange);

  gulp.watch(SCRIPTS, ['lint', 'scripts'])
    .on('change', logChange);

  gulp.watch(IMAGES, ['copy'])
    .on('change', logChange);

  gulp.watch(TEMPLATES, ['templates'])
    .on('change', logChange);
};

gulp.task('watch', watch);

module.exports = watch;
