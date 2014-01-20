{$}       = require '../vendors'
Section   = require './section.coffee'
ServerRow = require './server_row.coffee'
AddServer = require './add_server.coffee'
template  = require '../../templates/servers.mustache'

class Servers extends Section
  id:          'servers'
  template:    template
  rowView:     ServerRow
  addFormView: AddServer

  # override, since the servers section has no model
  # mebbe this model should be the one that holds user config?
  # who knows...
  dataEvents:
    'reset        collection': 'render'
    'add          collection': 'addModelAndUpdate'
    'request      collection': 'onRequest'
    'sync destroy collection': 'onSync'

  updateTitle: $.noop

  formatTitle: ->
    'Servers'

module.exports = Servers
