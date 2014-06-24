fs         = require 'fs'
path       = require 'path'

browserify = require 'browserify'
source     = require 'vinyl-source-stream'

gulp       = require 'gulp'
buffer     = require 'gulp-buffer'
bytediff   = require 'gulp-bytediff'
header     = require 'gulp-header'
notify     = require 'gulp-notify'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'

{log, colors} = require 'gulp-util'

hoganify   = require './hoganify'
resolver   = require './resolver'
rebundler  = require './rebundler'
livereload = require './livereload'

HEADER = fs.readFileSync('server/templates/banner.tpl')

HEADER_DATA =
  version: fs.readFileSync('VERSION')

# Compile and minify JavaScript source.
gulp.task 'scripts', ->
  log colors.blue('Compiling scripts')

  # Start with browserify...
  bundler = browserify(entries: './client/js/script.js', extensions: ['.coffee'], resolve: resolver, debug: true)
  bundler.on 'error', console.error

  script  = rebundler('client/js/script.js', bundler)()

  # And now pass it off to gulp
  script
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
