Giraffe = require '../shims/giraffe'

class Alert extends Giraffe.Model
  defaults:
    level: 'warning'
    block: false

  block: ->
    !!@get('block')

  level: ->
    level = @get('level')
    (if (level is 'error') then 'danger' else level)

  msg: ->
    @get 'msg'

module.exports = Alert
