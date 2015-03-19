gulp       = require 'gulp'
livereload = require 'gulp-livereload'
es         = require 'event-stream'

{log, colors} = require 'gulp-util'

server = undefined

# If the server has been started, pass changes through
reload = ->
  es.map (file, cb) ->
    server?.changed(file.path)
    cb(null, file)

# Start a LiveReload server instance.
reload.start = ->
  log colors.blue('Starting LiveReload server')

  server = livereload()

module.exports = reload
