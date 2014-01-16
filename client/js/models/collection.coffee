{_}         = require '../vendors'
Model       = require './model.coffee'
GenghisJSON = require '../json.coffee'
Util        = require '../util.coffee'
Documents   = require '../collections/documents.coffee'

_h = Util.humanizeSize

class Collection extends Model
  dataEvents:
    'change:id this': 'fetchDocuments'

  initialize: ->
    @documents = new Documents([], {coll: this})
    # @explain   = new Document([], {coll: this})
    super

  fetchDocuments: =>
    @documents.fetch(reset: true)

  indexesIsPlural: ->
    @indexCount() isnt 1

  indexCount: ->
    @get('indexes')?.length or 0

  indexes: ->
    _.map(_.pluck(@get('indexes'), 'key'), GenghisJSON.prettyPrint)

  isGridCollection: ->
    /\.files$/.test @get('name')

  humanSize: ->
    if stats = @get('stats')
      _h (stats.storageSize or 0) + (stats.totalIndexSize or 0)

  stats: ->
    if stats = @get('stats')
      [
        {name: 'Avg. object size', value: _h(stats.avgObjSize or 0)    }
        {name: 'Padding factor',   value: stats.paddingFactor or 'n/a' }
        {name: 'Data size',        value: _h(stats.size or 0)          }
        {name: 'Index size',       value: _h(stats.totalIndexSize or 0)}
        {name: 'Storage size',     value: _h(stats.storageSize or 0)   }
      ]

  truncate: (options = {}) ->
    options = _.clone(options)

    truncate = =>
      @trigger 'truncate', this, @collection, options

    success = options.success
    options.success = (resp) =>
      truncate() if options.wait or @isNew()
      success this, resp, options if success
      @trigger 'sync', this, resp, options unless @isNew()

    options.url = "#{@url()}/documents"

    if @isNew()
      options.success()
      return false

    error = options.error
    options.error = (resp) =>
      error this, resp, options if error
      @trigger 'error', this, resp, options

    xhr = @sync('delete', this, options)
    truncate() unless options.wait
    xhr

module.exports = Collection
