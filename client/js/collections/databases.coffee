Collection = require './collection.coffee'
Database   = require '../models/database.coffee'

class Databases extends Collection
  model: Database

module.exports = Databases
