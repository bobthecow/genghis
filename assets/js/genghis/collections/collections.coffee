define (require) ->
  BaseCollection = require("genghis/collections/base_collection")
  Collection     = require("genghis/models/collection")

  class Collections extends BaseCollection
    model: Collection

