Row      = require './row'
Confirm  = require './confirm'
template = require('../../templates/server_row.mustache').render

class ServerRow extends Row
  template: template

  destroy: =>
    name = (if @model.has('name') then @model.get('name') else '')
    new Confirm(
      header:      'Remove server?',
      body:        "Remove #{name} from the server list?<br><br>
                    This will not affect any data, and you can add it back at any time.",
      confirmText: "<strong>Yes</strong>, remove #{name} from server list",
      isDangerous: false,
      confirm: =>
        @model.destroy()
    )

module.exports = ServerRow
