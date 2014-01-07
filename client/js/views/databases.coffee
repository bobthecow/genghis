Section     = require './section.coffee'
DatabaseRow = require './database_row.coffee'
template    = require 'hgn!genghis/templates/databases'

class Databases extends Section
  el:       'section#databases'
  template: template
  rowView:  DatabaseRow
  formatTitle: (model) ->
    if model.id
      "#{model.id} Databases"
    else
      'Databases'

module.exports = Databases
