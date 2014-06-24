source        = require 'vinyl-source-stream'
path          = require 'path'
envify        = require 'envify/custom'

{log, colors} = require 'gulp-util'

hoganify      = require './hoganify'

module.exports = (name, bundler) ->
  logError = (error) ->
    log "Error bundling #{name}"
    console.log colors.red("  " + error.toString().replace(/\n/g, "\n  "))

  bundler
    .transform(hoganify)
    .transform('coffeeify')
    .transform(envify(
      API_URL: process.env.API_URL || 'http://api.bitflip.dev/v0'
    ))

  rebundle = ->
    bundler
      .bundle(debug: true)
      .on('error', logError)
      .pipe(source(path.basename(name)))

  rebundle
