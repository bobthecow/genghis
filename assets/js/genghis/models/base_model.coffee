define (require) ->
  Giraffe = require('backbone.giraffe')
  Util    = require('genghis/util')

  class BaseModel extends Giraffe.Model
    name:  -> @get 'name'
    count: -> @get 'count'

    humanCount: ->
      Util.humanizeCount(@get('count') or 0)

    isPlural: ->
      @get('count') isnt 1

    humanSize: ->
      if size = @get('size')
        Util.humanizeSize size

    hasMoreChildren: ->
      @get('count') > 15
