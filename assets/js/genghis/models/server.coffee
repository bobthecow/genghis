define (require) ->
  _         = require('underscore')
  BaseModel = require('genghis/models/base_model')

  class Server extends BaseModel
    editable: ->
      !!@get('editable')

    firstChildren: ->
      _.first (@get('databases') or []), 15

    error: ->
      @get 'error'
