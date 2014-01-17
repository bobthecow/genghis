Row      = require './row.coffee'
template = require '../../templates/database_row.mustache'

class DatabaseRow extends Row
  template: template

module.exports = DatabaseRow
