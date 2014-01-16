Collection = require './collection.coffee'
Database   = require '../models/database.coffee'

class Databases extends Collection
  model: Database

  url: =>
    "#{_.result(@server, 'url')}/databases"

module.exports = Databases
