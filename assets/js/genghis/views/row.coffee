define (require) ->
  $       = require('jquery')
  _       = require('underscore')
  View    = require('genghis/views/view')
  Util    = require('genghis/util')
  Confirm = require('genghis/views/confirm')

  require 'jquery.hoverintent'
  require 'bootstrap.tooltip'
  require 'bootstrap.popover'

  class Row extends View
    tagName: 'tr'
    events:
      'click a.name':         'navigate'
      'click button.destroy': 'destroy'

    modelEvents:
      'change':  'render'
      'destroy': 'remove'

    isParanoid: false

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


    navigate: (e) =>
      return if e.ctrlKey or e.shiftKey or e.metaKey
      e.preventDefault()
      app.router.navigate Util.route($(e.target).attr('href')), true

    destroy: =>
      model = @model
      name  = (if model.has('name') then model.get('name') else '')
      if @isParanoid
        throw 'Unable to confirm destruction without a confirmation string.' unless name
        new Confirm(
          header:       'Deleting is forever.'
          body:         "Type <strong>#{name}</strong> to continue:"
          confirmInput: name
          confirmText:  "Delete #{name} forever"
          confirm:      -> model.destroy()
        )
      else
        options =
          confirmText: @destroyConfirmButton(name)
          confirm:     -> model.destroy()

        options.body = @destroyConfirmText(name) if @destroyConfirmText
        new Confirm(options)

    destroyConfirmButton: (name) ->
      "<strong>Yes</strong>, delete #{name} forever"


