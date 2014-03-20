{$, Backbone} = require './vendors'
fs            = require 'fs'
App           = require './views/app'

module.exports =
  version: fs.readFileSync("#{__dirname}/../../VERSION"),
  boot: (baseUrl) ->
    $ ->
      baseUrl = "#{baseUrl}/" unless baseUrl[-1] is '/'
      app = window.app = new App(baseUrl: baseUrl)
      app.attachTo('body')
      Backbone.history.start(pushState: true, root: baseUrl)
