View      = require './view.coffee'
AlertView = require './alert.coffee'

class Alerts extends View
  id:        'alerts'
  tagName:   'aside'
  className: 'container'

  collectionEvents:
    'reset': 'render'
    'add':   'addModel'

  addModel: (model) ->
    @attach(new AlertView(model: model))

module.exports = Alerts
