Row      = require './row.coffee'
Confirm  = require './confirm.coffee'
template = require '../../templates/collection_row.mustache'

class CollectionRow extends Row
  template:   template

  events: _.extend({
    'click button.truncate': 'truncate'
  }, Row::events)

  truncate: ->
    name  = @model.get('name')
    count = @model.get('count') or 'all'

    new Confirm(
      header:       'Remove all documents?'
      body:         "Emptying this collection will remove <strong>#{count}
                     documents</strong>, but will leave indexes intact.
                     <br><br>Type <strong>#{name}</strong> to continue:"
      confirmInput: name
      confirmText:  "Empty #{name}"
      confirm: =>
        @model.truncate(wait: true)
          .fail(@app.alerts.handleError)
          .always(=> @model.fetch())
    )

module.exports = CollectionRow
