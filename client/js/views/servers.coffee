{$}       = require '../vendors'
Section   = require './section.coffee'
ServerRow = require './server_row.coffee'
template  = require '../../templates/servers.mustache'

class Servers extends Section
  id:       'servers'
  template: template
  rowView:  ServerRow

  # override, since the servers section has no model
  # mebbe this model should be the one that holds user config?
  # who knows...
  dataEvents:
    'reset        collection': 'render'
    'add          collection': 'addModelAndUpdate'
    'request      collection': 'startSpinning'
    'sync destroy collection': 'stopSpinning'

  afterRender: ->
    super
    # add placeholder help
    $('.help', @addForm).tooltip(container: 'body')

  submitAddForm: =>
    model = new @collection.model(url: @$addInput.val())
    model.collection = @collection
    model.save()
      .done( =>
        @collection.add(model)
        @closeAddForm()
      )
      .fail((xhr) => @app.alerts.handleError(xhr))

  updateTitle: $.noop

  formatTitle: ->
    'Servers'

module.exports = Servers
