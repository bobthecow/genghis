path = require 'path'
gulp = require 'gulp'

{log, colors} = require 'gulp-util'

livereload = require './livereload'

STYLES = [
  'client/css/**/*.{less,css}',
  'server/templates/banner.tpl',
]

SCRIPTS = [
  'client/js/**/*.{js,coffee}',
  'client/templates/**/*.mustache',
  'server/templates/banner.tpl',
]

IMAGES = [
  'client/img/**/*.*',
]

TEMPLATES = [
  'server/templates/{index,error}.mustache.tpl',
  'client/img/favicon.png',
]

logChange = (e) ->
  name = e.path.replace(path.dirname(__dirname) + '/', '')
  log colors.grey("File #{name} was #{e.type}, running tasks…")

watch = ->
  livereload.start()
  log colors.blue('Watching for changes')

  gulp.watch(STYLES, ['styles'])
    .on('change', logChange)

  gulp.watch(SCRIPTS, ['lint', 'scripts'])
    .on('change', logChange)

  gulp.watch(IMAGES, ['copy'])
    .on('change', logChange)

  gulp.watch(TEMPLATES, ['templates'])
    .on('change', logChange)

gulp.task 'watch', watch

module.exports = watch
