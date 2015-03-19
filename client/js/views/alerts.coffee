View      = require './view'
AlertView = require './alert'

class Alerts extends View
  id:        'alerts'
  tagName:   'aside'
  className: 'container'

  dataEvents:
    'reset collection': 'render'
    'add   collection': 'addModel'

  addModel: (model) ->
    @attach(new AlertView(model: model))

module.exports = Alerts
