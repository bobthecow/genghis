AddForm  = require './add_form'
template = require '../../templates/add_collection.mustache'

class AddCollection extends AddForm
  template: template

module.exports = AddCollection
