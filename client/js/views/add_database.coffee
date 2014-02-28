AddForm  = require './add_form'
template = require('../../templates/add_database.mustache').render

class AddDatabase extends AddForm
  template: template

module.exports = AddDatabase
