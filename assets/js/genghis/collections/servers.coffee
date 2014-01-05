define (require) ->
  _       = require('underscore')
  Giraffe = require('backbone.giraffe')
  Server  = require('genghis/models/document')

  class Servers extends Giraffe.Collection
    model: Server

    firstChildren: ->
      @collection.reject((m) -> m.has 'error')[0..9]

    hasMoreChildren: ->
      @collection.length > 10 or @collection.detect((m) -> m.has 'error')
