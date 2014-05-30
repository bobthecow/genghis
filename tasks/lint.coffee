gulp       = require 'gulp'
coffeelint = require 'gulp-coffeelint'
jshint     = require 'gulp-jshint'
map        = require 'map-stream'

{log, colors} = require 'gulp-util'


reportCoffee = (file, cb) ->
  unless file.coffeelint.success
    filename = file.path.replace("#{file.cwd}/", '')
    console.log "#{filename}:\n"
    file.coffeelint.results.forEach (error) ->
      color = (if error.level is 'error' then colors.red else colors.yellow)
      console.log color("  #{error.message}")
      console.log colors.grey("  #{filename}:#{error.lineNumber}\n")
  cb(null, file)

reportJS = (file, cb) ->
  unless file.jshint.success
    filename = file.path.replace("#{file.cwd}/", '')
    console.log "#{filename}:\n"
    file.jshint.results.forEach (result) ->
      if result.error
        console.log colors.red("  #{result.error.reason}")
        console.log colors.grey("  #{filename}:#{result.error.line}:#{result.error.character}\n")
  cb(null, file)


# Lint coffeescript and js.
#
# Currently only lints the client code.
# TODO: do this with the server code too.
gulp.task 'lint', ->
  log colors.blue('Linting client code')

  gulp.src([
    'client/js/**/*.coffee',
    '!client/js/json.coffee'
  ])
    .pipe(coffeelint(
      max_line_length:
        value: 120
        level: 'warn'
    ))
    .pipe(map(reportCoffee))

  gulp.src('client/js/json.coffee')
    .pipe(coffeelint(max_line_length:{level: 'ignore'}))
    .pipe(map(reportCoffee))

  # window, document, atob, etc.
  # we're rockin' node-style with browserify.
  gulp.src([
    'gulpfile.js',
    'tasks/**/*.js',
    'client/js/**/*.js',
    '!client/js/modernizr.js',
    '!tasks/source.js'
  ])
    .pipe(jshint(
      browser: true,
      node: true
    ))
    .pipe(map(reportJS))

