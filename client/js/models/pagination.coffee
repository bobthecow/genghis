{_, Giraffe} = require '../vendors'

class Pagination extends Giraffe.Model
  defaults:
    page:  1
    pages: 1
    limit: 50
    count: 0
    total: 0

module.exports = Pagination
