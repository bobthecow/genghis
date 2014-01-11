{_}   = require '../vendors'
Model = require './model.coffee'

class ServerStats extends Model
  url: ->
    @server.url()

module.exports = ServerStats
