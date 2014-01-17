Document = require './document.coffee'
Query    = require './query.coffee'

class Explain extends Document
  baseUrl: =>
    "#{_.result(@coll, 'url')}/explain"

  url: =>
    query = @query.toString(pretty: false)
    "#{@baseUrl()}#{query}"

module.exports = Explain
