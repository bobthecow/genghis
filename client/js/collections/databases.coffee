Collection = require './collection'
Database   = require '../models/database'

class Databases extends Collection
  model: Database

  url: =>
    "#{_.result(@server, 'url')}/databases"

module.exports = Databases
