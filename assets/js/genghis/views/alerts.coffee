define (require) ->
  View  = require('genghis/views/view')
  Alert = require('genghis/views/alert')

  class Alerts extends View
    el: 'aside#alerts'

    collectionEvents:
      'reset': 'render'
      'add':   'addModel'

    addModel: (model) ->
      @attach new Alert(model: model)
