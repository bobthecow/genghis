{$, _}  = require '../vendors'
View    = require './view'
Util    = require '../util'
Confirm = require './confirm'

class Row extends View
  tagName: 'tr'
  events:
    'click a.name':         'navigate'
    'click button.destroy': 'destroy'

  dataEvents:
    'change  model': 'render'
    'destroy model': 'dispose'

  afterRender: ->
    @$el
      .toggleClass('error', @model.get('error'))
      .find('.label[title]')
      .tooltip(placement: 'bottom')

    @$('.has-details')
      .popover(
        html:    true,
        title:   -> $(this).siblings('.details').attr('title'),
        content: -> $(this).siblings('.details').html(),
        trigger: 'manual'
      )
      .hoverIntent(
        (-> $(this).popover 'show'),
        (-> $(this).popover 'hide')
      )

  navigate: (e) ->
    return if e.ctrlKey or e.shiftKey or e.metaKey
    e.preventDefault()
    app.router.navigate Util.route($(e.target).attr('href')), true

  destroy: =>
    name = (if @model.has('name') then @model.get('name') else '')
    throw new Error('Unable to confirm distruction without a confirmation string.') unless name
    new Confirm(
      header:       'Deleting is forever.',
      body:         "Type <strong>#{name}</strong> to continue:",
      confirmInput: name,
      confirmText:  "Delete #{name} forever",
      confirm: =>
        @model.destroy()
    )

module.exports = Row
