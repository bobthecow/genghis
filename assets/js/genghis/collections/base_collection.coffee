define (require) ->
  Giraffe = require('backbone.giraffe')

  class BaseCollection extends Giraffe.Collection
    firstChildren:   -> @collection.toArray()[0..10]
    hasMoreChildren: -> @collection.length > 10
