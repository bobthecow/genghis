fs           = require 'fs'
path         = require 'path'

gulp         = require 'gulp'
autoprefixer = require 'gulp-autoprefixer'
bytediff     = require 'gulp-bytediff'
concat       = require 'gulp-concat'
csso         = require 'gulp-csso'
header       = require 'gulp-header'
less         = require 'gulp-less'
# notify       = require 'gulp-notify'
rename       = require 'gulp-rename'

{log, colors} = require 'gulp-util'

livereload = require './livereload'
datauri    = require './datauri'

HEADER      = fs.readFileSync('server/templates/banner.tpl')

HEADER_DATA =
  version: fs.readFileSync('VERSION')

# Compile and concatenate LESS (and other) stylesheets.
gulp.task 'styles', ->
  log colors.blue('Compiling stylesheets')

  # Minified
  gulp.src('client/css/style.less')
    .pipe(less(
      paths: [path.join(path.dirname(__dirname), 'assets', 'css')]
    ))
    .pipe(concat('style.css'))
    .pipe(header(HEADER, HEADER_DATA))
    .pipe(bytediff.start())
    .pipe(gulp.dest('public/css'))
    .pipe(livereload())
    # .pipe(notify('Stylesheet updated'))
    .pipe(rename(suffix: '.min'))
    .pipe(datauri(
      base:   'client/css/',
      target: 'client/img/backgrounds/*.*'
    ))
    .pipe(autoprefixer())
    .pipe(csso())
    .pipe(header(HEADER, HEADER_DATA))
    .pipe(bytediff.stop())
    .pipe(gulp.dest('public/css'))
    # .pipe(notify('Minified stylesheet updated'));
