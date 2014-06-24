AddForm  = require './add_form'
template = require '../../templates/add_database.mustache'

class AddDatabase extends AddForm
  template: template

module.exports = AddDatabase
