{Giraffe} = require '../vendors'
Alert     = require '../models/alert.coffee'

isBlock = (msg) ->
  not msg.search(/<(p|ul|ol|div)[ >]/)

class Alerts extends Giraffe.Collection
  model: Alert

  handleError: (response) =>
    return if response.readyState is 0
    try
      data = JSON.parse(response.responseText)
    msg = data?.error or response.responseText or "<strong>FAIL</strong> An unexpected server error has occurred."
    @add(level: 'danger', msg: msg, block: isBlock(msg))

module.exports = Alerts
