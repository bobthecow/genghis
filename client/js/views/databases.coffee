Section     = require './section'
DatabaseRow = require './database_row'
AddDatabase = require './add_database'
template    = require('../../templates/databases.mustache').render

class Databases extends Section
  id:          'databases'
  template:    template
  rowView:     DatabaseRow
  addFormView: AddDatabase
  title:  =>
    if @model.id then "#{@model.id} Databases" else 'Databases'

module.exports = Databases
