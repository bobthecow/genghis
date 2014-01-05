define (require) ->
  Section     = require('genghis/views/section')
  DatabaseRow = require('genghis/views/database_row')
  template    = require('hgn!genghis/templates/databases')
  Section.extend
    el:       'section#databases'
    template: template
    rowView:  DatabaseRow
    formatTitle: (model) ->
      if model.id
        "#{model.id} Databases"
      else
        'Databases'
