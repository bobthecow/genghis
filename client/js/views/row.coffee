{$, _}  = require '../vendors'
View    = require './view.coffee'
Util    = require '../util.coffee'
Confirm = require './confirm.coffee'

class Row extends View
  tagName: 'tr'
  events:
    'click a.name':         'navigate'
    'click button.destroy': 'destroy'

  modelEvents:
    'change':  'render'
    'destroy': 'remove'

  initialize: ->
    # TODO: figure out why remove doesn't like us and stop doing this.
    _.bindAll(this, 'remove')

  afterRender: ->
    @$el
      .toggleClass('error', @model.get('error'))
      .find('.label[title]')
      .tooltip(placement: 'bottom')

    @$('.has-details').popover(
      html:    true
      content: ->
        $(this).siblings('.details').html()
      title: ->
        $(this).siblings('.details').attr('title')
      trigger: 'manual'
    ).hoverIntent (-> $(this).popover 'show'), (-> $(this).popover 'hide')

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
