Row      = require './row'
template = require('../../templates/database_row.mustache').render

class DatabaseRow extends Row
  template: template

module.exports = DatabaseRow
