{$, Backbone} = require './shims/vendors'
App           = require './views/app.coffee'

module.exports = (baseUrl) ->
  $ ->
    baseUrl = baseUrl + '/' unless baseUrl[-1] == '/'
    window.app = new App(baseUrl: baseUrl)
    Backbone.history.start(pushState: true, root: baseUrl)
