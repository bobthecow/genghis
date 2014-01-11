View     = require './view.coffee'
template = require '../../templates/alert.mustache'

class Alert extends View
  template: template

  events:
    'click button.close': 'destroy'

  modelEvents:
    'change':   'render'
    'disposed': 'dispose'

  afterRender: ->
    # A bit ghetto, but whatevs.
    @$('a').addClass 'alert-link'

  destroy: ->
    @model.dispose()

module.exports = Alert
