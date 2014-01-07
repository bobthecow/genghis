_       = require 'underscore'
Giraffe = require '../shims/giraffe'
Server  = require '../models/document.coffee'

class Servers extends Giraffe.Collection
  model: Server

  firstChildren: ->
    @collection.reject((m) -> m.has 'error')[0..9]

  hasMoreChildren: ->
    @collection.length > 10 or @collection.detect((m) -> m.has 'error')

module.exports = Servers
