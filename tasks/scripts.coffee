fs         = require 'fs'
path       = require 'path'

browserify = require 'browserify'

gulp       = require 'gulp'
buffer     = require 'gulp-buffer'
bytediff   = require 'gulp-bytediff'
header     = require 'gulp-header'
notify     = require 'gulp-notify'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'

{log, colors} = require 'gulp-util'

# TODO: replace this when upstream gets its act together.
source     = require('./source')
livereload = require './livereload'


HEADER = fs.readFileSync('server/templates/banner.tpl')

HEADER_DATA =
  version: fs.readFileSync('VERSION')

# Compile and minify JavaScript source.
gulp.task 'scripts', ->
  log colors.blue('Compiling scripts')

  # Start with browserify...
  browserify(extensions: ['.coffee'])
    .add('./client/js/script.js')
    .transform('browserify-hogan')
    .transform('coffeeify')
    .transform('debowerify')
    .transform('brfs')
    .bundle(debug: true)

    # And now pass it off to gulp
    .pipe(source('client/js/script.js'))
    .pipe(buffer()) # this pipeline doesn't play nice with vinyl-source-stream

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
