{_}   = require '../vendors'
Model = require './model.coffee'

class Server extends Model
  editable: ->
    !!@get('editable')

  firstChildren: ->
    _.first (@get('databases') or []), 15

  error: ->
    @get 'error'

module.exports = Server
