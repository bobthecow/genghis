{_}       = require '../vendors'
Model     = require './model'
Databases = require '../collections/databases'

class Server extends Model
  dataEvents:
    'sync this': 'fetchDatabases'

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
