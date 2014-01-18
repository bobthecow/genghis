Document = require './document.coffee'
Search   = require './search.coffee'

class Explain extends Document
  baseUrl: =>
    "#{_.result(@coll, 'url')}/explain"

  url: =>
    base  = @baseUrl()
    search = @search.toString(pretty: false)
    "#{base}#{search}"

module.exports = Explain
