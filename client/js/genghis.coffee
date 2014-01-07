fs = require 'fs'

module.exports = {
  version: fs.readFileSync("#{__dirname}/../../VERSION.txt")
}
