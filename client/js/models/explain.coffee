Document = require './document'
Search   = require './search'

class Explain extends Document
  baseUrl: =>
    "#{_.result(@coll, 'url')}/explain"

  url: =>
    base  = @baseUrl()
    search = @search.toString(pretty: false)
    "#{base}#{search}"

module.exports = Explain
