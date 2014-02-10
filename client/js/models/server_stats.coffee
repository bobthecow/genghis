{_}   = require '../vendors'
Model = require './model'

class ServerStats extends Model
  url: ->
    @server.url()

module.exports = ServerStats
