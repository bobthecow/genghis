Section     = require './section'
DatabaseRow = require './database_row'
AddDatabase = require './add_database'
template    = require '../../templates/databases.mustache'

class Databases extends Section
  id:          'databases'
  template:    template
  rowView:     DatabaseRow
  addFormView: AddDatabase

  formatTitle: (model) ->
    if model.id
      "#{model.id} Databases"
    else
      'Databases'

module.exports = Databases
