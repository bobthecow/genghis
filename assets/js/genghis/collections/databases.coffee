define (require) ->
  BaseCollection = require('genghis/collections/base_collection')
  Database       = require('genghis/models/database')

  class Databases extends BaseCollection
    model: Database
