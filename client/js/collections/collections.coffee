BaseCollection = require './collection.coffee'
Collection     = require '../models/collection.coffee'

class Collections extends BaseCollection
  model: Collection

module.exports = Collections
