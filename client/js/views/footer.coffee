View          = require './view'
ShortcutsView = require './keyboard_shortcuts'
template      = require('../../templates/footer.mustache').render

class Footer extends View
  id:        'footer'
  tagName:   'footer'
  className: 'container'
  template:  template

  events:
    'click a.keyboard-shortcuts': 'showShortcuts'

  afterRender: ->
    @shortcuts = new ShortcutsView()
    @attach(@shortcuts)

  showShortcuts: (e) ->
    @shortcuts.show(e)

module.exports = Footer
