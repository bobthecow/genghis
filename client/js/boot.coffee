{$, Backbone} = require './vendor'
AppView       = require './views/app.coffee'

module.exports = (baseUrl) ->
  $ ->
    baseUrl = baseUrl + '/' unless baseUrl[-1] == '/'
    window.app = new AppView(baseUrl: baseUrl)
    Backbone.history.start(pushState: true, root: baseUrl)
