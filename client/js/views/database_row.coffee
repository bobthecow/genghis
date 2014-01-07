Row      = require './row.coffee'
template = require '../../templates/database_row.mustache'

class DatabaseRow
  template:   template
  isParanoid: true

module.exports = DatabaseRow
