Document = require './document.coffee'

class Explain extends Document
  url: =>
    "#{_.result(@coll, 'url')}/explain"

module.exports = Explain
