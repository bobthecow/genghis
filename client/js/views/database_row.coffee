Row      = require './row.coffee'
template = require 'hgn!genghis/templates/database_row'

class DatabaseRow
  template:   template
  isParanoid: true

module.exports = DatabaseRow
