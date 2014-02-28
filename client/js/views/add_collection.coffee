AddForm  = require './add_form'
template = require('../../templates/add_collection.mustache').render

class AddCollection extends AddForm
  template: template

module.exports = AddCollection
