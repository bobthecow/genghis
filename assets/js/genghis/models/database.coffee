define (require) ->
  _         = require('underscore')
  BaseModel = require('genghis/models/base_model')
  Util      = require('genghis/util')

  _h = Util.humanizeSize

  BaseModel.extend
    firstChildren: ->
      _.first (@get('collections') or []), 15

    humanSize: ->
      if stats = @get('stats')
        Util.humanizeSize (stats.fileSize or 0) + (stats.indexSize or 0)

    stats: ->
      if stats = @get('stats')
        [
          {name: 'Avg. object size', value: _h(stats.avgObjSize or 0) }
          {name: 'Data size',        value: _h(stats.dataSize or 0)   }
          {name: 'Index size',       value: _h(stats.indexSize or 0)  }
          {name: 'Storage size',     value: _h(stats.fileSize or 0)   }
        ]

    error: ->
      @get 'error'
