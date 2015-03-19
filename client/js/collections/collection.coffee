{Giraffe} = require '../vendors'

class Collection extends Giraffe.Collection
  firstChildren:   -> @collection.toArray()[0..10]
  hasMoreChildren: -> @collection.length > 10

module.exports = Collection
