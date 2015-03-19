fs       = require 'fs'
path     = require 'path'
stream   = require 'event-stream'
datauri  = require 'datauri'

gulp     = require 'gulp'
bytediff = require 'gulp-bytediff'
htmlmin  = require 'gulp-htmlmin'
# notify   = require 'gulp-notify'
rename   = require 'gulp-rename'
template = require 'gulp-template'

{log, colors} = require 'gulp-util'

livereload = require './livereload'

# Compile page templates.
gulp.task 'templates', ->
  log colors.blue('Compiling templates')

  dev = gulp.src('server/templates/{index,error}.tpl')
    .pipe(rename(extname: '.mustache'))
    .pipe(template(favicon: '{{ base_url }}/img/favicon.png'))
    .pipe(gulp.dest('public/templates'))
    .pipe(livereload())
    # .pipe(notify(
    #   message: 'Templates updated',
    #   onLast:  true
    # ))

  dist = gulp.src('server/templates/{index,error}.tpl')
    .pipe(rename(extname: '.min.mustache'))
    .pipe(template(favicon: datauri('client/img/favicon.png')))
    .pipe(bytediff.start())
    .pipe(htmlmin(
      removeComments: true,
      collapseWhitespace: true,
      collapseBooleanAttributes: true,
      removeRedundantAttributes: true,
      removeEmptyAttributes: true
    ))
    .pipe(bytediff.stop())
    .pipe(gulp.dest('public/templates'))
    # .pipe(notify(
    #   message: 'Minified templates updated',
    #   onLast:  true
    # ))

  stream.concat(dev, dist)
