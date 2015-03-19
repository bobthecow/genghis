{Giraffe} = require '../vendors'
Alert     = require '../models/alert'

isBlock = (msg) ->
  not msg.search(/<(p|ul|ol|div)[ >]/)

getMsg = (xhr) ->
  data = if xhr.responseJSON? then xhr.responseJSON else JSON.parse(xhr.responseText)
  data?.error or xhr.responseText or "<strong>FAIL</strong> An unexpected server error has occurred."

class Alerts extends Giraffe.Collection
  model: Alert

  handleError: (xhr) =>
    return if xhr.readyState is 0
    msg = getMsg(xhr)
    @add(level: 'danger', msg: msg, block: isBlock(msg))

module.exports = Alerts
