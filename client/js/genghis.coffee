{$, Backbone} = require './vendors'
fs            = require 'fs'
App           = require './views/app.coffee'

class Genghis
  version: fs.readFileSync("#{__dirname}/../../VERSION.txt"),
  boot: (baseUrl) ->
    $ ->
      baseUrl = "#{baseUrl}/" unless baseUrl[-1] is '/'
      window.app = new App(baseUrl: baseUrl)
      Backbone.history.start(pushState: true, root: baseUrl)

module.exports = Genghis
