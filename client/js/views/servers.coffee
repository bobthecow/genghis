{$}       = require '../vendors'
Section   = require './section'
ServerRow = require './server_row'
AddServer = require './add_server'
template  = require('../../templates/servers.mustache').render

class Servers extends Section
  id:          'servers'
  template:    template
  rowView:     ServerRow
  addFormView: AddServer
  title:       'Servers'

  # override, since the servers section has no model
  # mebbe this model should be the one that holds user config?
  # who knows...
  dataEvents:
    'reset        collection': 'render'
    'add          collection': 'addModelAndUpdate'
    'request      collection': 'onRequest'
    'sync destroy collection': 'onSync'

module.exports = Servers
