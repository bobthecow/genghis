define (require) ->
  $        = require('jquery')
  Backbone = require('backbone-stack')
  AppView  = require('genghis/views/app')

  (baseUrl) ->
    $ ->
      baseUrl = baseUrl + '/' unless baseUrl[-1] == '/'
      window.app = new AppView(baseUrl: baseUrl)
      Backbone.history.start
        pushState: true
        root: baseUrl
