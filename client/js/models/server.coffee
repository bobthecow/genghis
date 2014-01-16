{_}       = require '../vendors'
Model     = require './model.coffee'
Databases = require '../collections/databases.coffee'

class Server extends Model
  dataEvents:
    'change:id this': 'fetchDatabases'

  initialize: (opts) ->
    @databases = new Databases([], {server: this})
    super

  fetchDatabases: =>
    @databases.fetch(reset: true)

  editable: ->
    !!@get('editable')

  firstChildren: ->
    _.first (@get('databases') or []), 15

  error: ->
    @get 'error'

module.exports = Server
