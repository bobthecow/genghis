AddForm  = require './add_form'
template = require('../../templates/add_server.mustache').render

class AddServer extends AddForm
  template: template

  afterRender: ->
    super
    # add placeholder help
    @$('.help').tooltip(container: 'body')

  createModel: =>
    new @collection.model(url: @$input.val())

module.exports = AddServer
