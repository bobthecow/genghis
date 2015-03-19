{$, Backbone} = require './vendors'
App           = require './views/app'

module.exports =
  version: process.env.VERSION,
  boot: (baseUrl) ->
    $ ->
      baseUrl = "#{baseUrl}/" unless baseUrl[-1] is '/'
      app = window.app = new App(baseUrl: baseUrl)
      app.attachTo('body')
      Backbone.history.start(pushState: true, root: baseUrl)
