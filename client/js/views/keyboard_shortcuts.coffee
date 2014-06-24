{$, _}   = require '../vendors'
View     = require './view'
template = require '../../templates/keyboard_shortcuts.mustache'

class KeyboardShortcuts extends View
  id:        'keyboard-shortcuts'
  tagName:   'div'
  className: 'modal'
  template:  template

  events:
    'click button.close': 'hide'

  keyboardEvents:
    '?': 'toggle'

  afterRender: ->
    @$el.modal(backdrop: true, show: false)
      .on({
        'shown.bs.modal': @bindEscape,
        'hide.bs.modal':  @unbindEscape
      })

  show: (e) =>
    e?.preventDefault()
    @$el.modal('show')

  hide: (e) =>
    e?.preventDefault()
    @$el.modal('hide')

  toggle: =>
    @$el.modal('toggle')

  bindEscape: =>
    @bindKeyboardEvents(esc: 'hide', enter: 'hide')

  unbindEscape: =>
    @unbindKeyboardEvents() # unbind everything to clear the esc/enter
    @bindKeyboardEvents()   # ... and then re-bind the ? key.

module.exports = KeyboardShortcuts
