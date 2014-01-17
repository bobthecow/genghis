{_}            = require '../vendors'
BaseCollection = require './collection.coffee'
Collection     = require '../models/collection.coffee'

class Collections extends BaseCollection
  model: Collection

  url: =>
    "#{_.result(@database, 'url')}/collections"

module.exports = Collections
