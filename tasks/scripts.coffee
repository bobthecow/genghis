fs         = require 'fs'
path       = require 'path'

gulp       = require 'gulp'
buffer     = require 'gulp-buffer'
bytediff   = require 'gulp-bytediff'
header     = require 'gulp-header'
named      = require 'vinyl-named'
notify     = require 'gulp-notify'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
webpack    = require 'gulp-webpack'

{log, colors} = require 'gulp-util'

livereload = require './livereload'

HEADER = fs.readFileSync('server/templates/banner.tpl')

HEADER_DATA =
  version: fs.readFileSync('VERSION')

# Compile and minify JavaScript source.
gulp.task 'scripts', ->
  log colors.blue('Compiling scripts')

  gulp.src('client/js/script.js')
    .pipe(named())
    .pipe(webpack(require('../webpack.config')))
    .pipe(gulp.dest('public/js'))

    # Normal
    .pipe(bytediff.start())
    .pipe(gulp.dest('public/js'))
    #.pipe(notify('Script updated'))
    .pipe(livereload())

    # Minified
    .pipe(rename(suffix: '.min'))
    .pipe(uglify(output: {ascii_only: true}))
    .pipe(header(HEADER, HEADER_DATA))
    .pipe(bytediff.stop())
    .pipe(gulp.dest('public/js'))
    #.pipe(notify('Minified script updated'))
