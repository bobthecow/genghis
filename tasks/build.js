var fs       = require('fs');

var gulp     = require('gulp');
var concat   = require('gulp-concat');
var header   = require('gulp-header');
// var notify   = require('gulp-notify');
var rename   = require('gulp-rename');
var replace  = require('gulp-replace');
var spawn    = require('gulp-spawn');
var template = require('gulp-template');

var gutil    = require('gulp-util');
var log      = gutil.log;
var colors   = gutil.colors;

var VERSION = fs.readFileSync('VERSION.txt');

var assetName = function(file) {
  return file.path.replace(/^.*?public\/(templates\/)?|/, '').replace('.min.', '.');
};

// Internal builds for distribution...
gulp.task('build:assets', ['styles', 'scripts', 'templates', 'copy'], function() {
  log(colors.blue('Building assets'));

  return gulp.src([
    'public/js/script.min.js',
    'public/css/style.min.css',
    'public/templates/index.min.mustache',
    'public/templates/error.min.mustache'
  ])
    .pipe(header("\n@@ <%= name(file) %>\n", {name: assetName}))
    .pipe(concat('assets.txt'))
    .pipe(gulp.dest('tmp'));
});


gulp.task('build:php:lib', function() {
  log(colors.blue('Compiling PHP libraries'));

  return gulp.src(['server/php/**/*.php', '!server/php/Genghis/AssetLoader/Dev.php'])
    .pipe(spawn({cmd: 'php', args: ['-w']}))
    .pipe(replace(/^(<\?php\n\s*|\s*$)/g, ''))
    .pipe(concat('lib.php'))
    .pipe(gulp.dest('tmp'));
});


gulp.task('build:php', function() {
  log(colors.blue('Compiling PHP backend'));

  gulp.src('server/templates/genghis.php.tpl')
    .pipe(template({
      version:  VERSION,
      includes: fs.readFileSync('tmp/lib.php'),
      assets:   fs.readFileSync('tmp/assets.txt')
    }))
    .pipe(rename('genghis.php'))
    .pipe(gulp.dest('.'));
    // .pipe(notify('genghis.php updated'));
});


gulp.task('build:rb:lib', function() {
  log(colors.blue('Compiling Ruby libraries'));

  return gulp.src([
    'server/rb/genghis/json.rb',
    'server/rb/genghis/errors.rb',
    'server/rb/genghis/models/**/*',
    'server/rb/genghis/helpers.rb',
    'server/rb/genghis/server.rb'
  ])
    .pipe(concat('lib.rb'))
    .pipe(gulp.dest('tmp'));
});


gulp.task('build:rb', function() {
  log(colors.blue('Compiling Ruby backend'));

  gulp.src('server/templates/genghis.rb.tpl')
    .pipe(template({
      version:  VERSION,
      includes: fs.readFileSync('tmp/lib.rb'),
      assets:   fs.readFileSync('tmp/assets.txt')
    }))
    .pipe(rename('genghis.rb'))
    .pipe(gulp.dest('.'));
    // .pipe(notify('Genghis.rb updated'));
});


// Build Genghis.
gulp.task('build', ['build:assets', 'build:rb:lib', 'build:php:lib'], function() {
  gulp.run('build:rb', 'build:php');
});


// Rebuild Genghis.
gulp.task('rebuild', ['clean'], function() {
  gulp.run('build');
});
