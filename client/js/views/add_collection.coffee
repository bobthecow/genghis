AddForm  = require './add_form.coffee'
template = require '../../templates/add_collection.mustache'

class AddCollection extends AddForm
  template: template

module.exports = AddCollection
