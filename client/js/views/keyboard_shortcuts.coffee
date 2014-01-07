$        = require 'jquery'
_        = require 'underscore'
View     = require './view.coffee'
template = require 'hgn!genghis/templates/keyboard_shortcuts'

require 'bootstrap.modal'
require 'backbone.mousetrap'

class KeyboardShortcuts extends View
  tagName:   'div'
  id:        'keyboard-shortcuts'
  className: 'modal'
  template:  template

  events:
    'click button.close': 'hide'

  keyboardEvents:
    '?': 'toggle'

  initialize: ->
    @render()

  afterRender: ->
    $('footer a.keyboard-shortcuts').click(@show).show()
    @$el.modal(backdrop: true, keyboard: true, show: false)

  show: (e) =>
    e.preventDefault()
    @$el.modal 'show'

  hide: (e) =>
    e.preventDefault()
    @$el.modal 'hide'

  toggle: =>
    @$el.modal 'toggle'

module.exports = KeyboardShortcuts
