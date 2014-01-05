define (require) ->
  _           = require('underscore')
  Giraffe     = require('backbone.giraffe')
  Util        = require('genghis/util')
  GenghisJSON = require('genghis/json')

  e = encodeURIComponent

  class Document extends Giraffe.Model
    idAttribute: null

    parse: (resp) ->
      # a little bitta id thunk.
      if id = Util.encodeDocumentId(resp._id)
        @id = id
      resp

    url: ->
      getUrl = (object) ->
        return null unless object?.url
        if _.isFunction(object.url) then object.url() else object.url

      base = getUrl(@collection) or @urlRoot or urlError()
      base = base.split('?').shift()
      base = base[0..-2] if base[-1] is "/"

      if @isNew()
        base
      else
        "#{base}/#{e(@id)}"

    prettyId: =>
      id = @get('_id')
      if _.isObject(id) and id.$genghisType
        switch id.$genghisType
          when 'ObjectId'
            return id.$value
          when 'BinData'
            # Special case: UUID
            if id.$value.$subtype is 3
              uuid = /^([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})$/i
              hex  = Util.base64ToHex(id.$value.$binary)
              return hex.replace(uuid, '$1-$2-$3-$4-$5') if uuid.test(hex)

            return id.$value.$binary.replace(/\=+$/, '')

      # Make null and hash IDs prettier
      GenghisJSON.stringify id, false

    prettyTime: =>
      if not @collection or @collection.guessCreationTime
        if typeof @_prettyTime is 'undefined'
          id = @get('_id')
          if _.isObject(id) and id.$genghisType
            if id.$genghisType is 'ObjectId' and id.$value.length is 24
              time = new Date()
              time.setTime parseInt(id.$value.substring(0, 8), 16) * 1000
              @_prettyTime = time.toUTCString()
        @_prettyTime

    prettyPrint: => GenghisJSON.prettyPrint @toJSON()
    JSONish:     => GenghisJSON.stringify   @toJSON()

    isGridFile: =>
      # define grid files as: in a grid collection and has a chunkSize
      @get('chunkSize') and /\.files\/documents\//.test(@url())

    isGridChunk: =>
      # define grid files as: in a grid chunks collection and has a files_id
      @get('files_id') and /\.chunks\/documents\//.test(@url())

    downloadUrl: =>
      throw 'Not a GridFS file.' unless @isGridFile()
      @url().replace /\.files\/documents\//, '.files/files/'

    fileUrl: =>
      throw 'Not a GridFS chunk.' unless @isGridChunk()
      @url()
        .replace(/\.chunks\/documents\//, '.files/documents/')
        .replace(@id, Util.encodeDocumentId(@get('files_id')))
