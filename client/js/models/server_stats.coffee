{_}   = require '../vendors'
Model = require './model.coffee'

class ServerStats extends Model
  initialize: (attrs, options = {}) ->
    {@server} = options

  url: ->
    @server.url()

module.exports = ServerStats
