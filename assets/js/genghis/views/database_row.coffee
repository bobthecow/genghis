define (require) ->
  Row      = require("genghis/views/row")
  template = require("hgn!genghis/templates/database_row")

  class DatabaseRow
    template:   template
    isParanoid: true


