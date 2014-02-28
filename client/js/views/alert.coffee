View     = require './view'
template = require('../../templates/alert.mustache').render

class Alert extends View
  template: template

  events:
    'click button.close': 'destroy'

  dataEvents:
    'change   model': 'render'
    'disposed model': 'dispose'

  afterRender: ->
    # A bit ghetto, but whatevs.
    @$('a').addClass 'alert-link'

  destroy: ->
    @model.dispose()

module.exports = Alert
