{_}            = require '../vendors'
BaseCollection = require './collection'
Collection     = require '../models/collection'

class Collections extends BaseCollection
  model: Collection

  url: =>
    "#{_.result(@database, 'url')}/collections"

module.exports = Collections
