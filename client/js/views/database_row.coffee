Row      = require './row'
template = require '../../templates/database_row.mustache'

class DatabaseRow extends Row
  template: template

module.exports = DatabaseRow
