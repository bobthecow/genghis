define (require) ->
  $         = require('jquery')
  Section   = require('genghis/views/section')
  ServerRow = require('genghis/views/server_row')
  template  = require('hgn!genghis/templates/servers')

  require 'bootstrap.tooltip'

  Section.extend
    el:       'section#servers'
    template: template
    rowView:  ServerRow

    # override, since the servers section has no model
    # mebbe this model should be the one that holds user config?
    # who knows...
    modelEvents: null

    afterRender: ->
      super
      # add placeholder help
      $('.help', @addForm).tooltip(container: 'body')

    submitAddForm: ->
      {alerts} = @app
      @collection.create(
        (url: @$addInput.val())
        wait: true
        success: @closeAddForm
        error: (model, response) -> alerts.handleError response
      )

    updateTitle: $.noop

    formatTitle: ->
      "Servers"
