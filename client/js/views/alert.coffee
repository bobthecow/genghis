View     = require './view.coffee'
template = require 'hgn!genghis/templates/alert'

class Alert extends View
  tagName:  'div'
  template: template

  events:
    'click button.close': 'destroy'

  modelEvents:
    'change':  'render'
    'destroy': 'remove'

  afterRender: ->
    @$('a').addClass 'alert-link'

  destroy: ->
    @model.destroy()

module.exports = Alert
