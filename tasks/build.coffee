fs       = require 'fs'

gulp     = require 'gulp'
concat   = require 'gulp-concat'
header   = require 'gulp-header'
# notify   = require 'gulp-notify'
rename   = require 'gulp-rename'
replace  = require 'gulp-replace'
spawn    = require 'gulp-spawn'
template = require 'gulp-template'

{log, colors} = require 'gulp-util'

VERSION  = fs.readFileSync('VERSION')

assetName = (file) ->
  file.path.replace(/^.*?public\/(templates\/)?|/, '').replace('.min.', '.')

# Internal builds for distribution...
gulp.task 'build:assets', ['styles', 'scripts', 'templates', 'copy'], ->
  log colors.blue('Packaging assets')

  gulp.src([
    'public/js/script.min.js',
    'public/css/style.min.css',
    'public/templates/index.min.mustache',
    'public/templates/error.min.mustache'
  ])
    .pipe(header("\n@@ <%= name(file) %>\n", name: assetName))
    .pipe(concat('assets.txt'))
    .pipe(gulp.dest('tmp'))


gulp.task 'build:php:lib', ->
  log colors.blue('Packaging PHP libraries')

  gulp.src([
    'server/php/**/*.php',
    '!server/php/Genghis/AssetLoader/Dev.php'
  ])
    .pipe(spawn(cmd: 'php', args: ['-w']))
    .pipe(replace(/^(<\?php\n\s*|\s*$)/g, ''))
    .pipe(concat('lib.php'))
    .pipe(gulp.dest('tmp'))


gulp.task 'build:php', ['build:assets', 'build:php:lib'], ->
  log colors.blue('Building PHP backend')

  gulp.src('server/templates/genghis.php.tpl')
    .pipe(template(
      version:  VERSION,
      includes: fs.readFileSync('tmp/lib.php'),
      assets:   fs.readFileSync('tmp/assets.txt')
    ))
    .pipe(rename('genghis.php'))
    .pipe(gulp.dest('.'))
    # .pipe(notify('genghis.php updated'))

gulp.task 'build:rb:lib', ->
  log colors.blue('Packaging Ruby libraries')

  gulp.src([
    'server/rb/genghis/json.rb',
    'server/rb/genghis/errors.rb',
    'server/rb/genghis/models/**/*',
    'server/rb/genghis/helpers.rb',
    'server/rb/genghis/server.rb'
  ])
    .pipe(concat('lib.rb'))
    .pipe(gulp.dest('tmp'))

gulp.task 'build:rb', ['build:assets', 'build:rb:lib'], ->
  log colors.blue('Building Ruby backend')

  gulp.src('server/templates/genghis.rb.tpl')
    .pipe(template(
      version:  VERSION,
      includes: fs.readFileSync('tmp/lib.rb'),
      assets:   fs.readFileSync('tmp/assets.txt')
    ))
    .pipe(rename('genghis.rb'))
    .pipe(gulp.dest('.'))
    # .pipe(notify('Genghis.rb updated'))


# Build Genghis.
gulp.task 'build', ['build:rb', 'build:php']


# Rebuild Genghis.
gulp.task 'rebuild', ['clean'], ->
  gulp.run('build')
