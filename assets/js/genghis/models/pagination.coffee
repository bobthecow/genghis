define (require) ->
  _       = require('underscore')
  Giraffe = require('backbone.giraffe')

  class Pagination extends Giraffe.Model
    defaults:
      page:  1
      pages: 1
      limit: 50
      count: 0
      total: 0

    decrementTotal: =>
      @set
        total: @get('total') - 1
        count: @get('count') - 1



