{_, Giraffe} = require '../vendors'
Util         = require '../util.coffee'
GenghisJSON  = require '../json.coffee'

stringify = (val) ->
  GenghisJSON.stringify(val, false)

class Query extends Giraffe.Model
  defaults:
    query:  {}
    fields: {}
    sort:   {}
    page:   1

  toQuery: (opts = {}) =>
    params = {}
    _j = if opts.pretty then JSON.stringify else stringify

    if q = opts.query or @get('query')
      params.q = _j(q) unless _.isEmpty(q)

    if fields = opts.fields or @get('fields')
      params.fields = _j(fields) unless _.isEmpty(fields)

    if sort = opts.sort or @get('sort')
      params.sort = _j(sort) unless _.isEmpty(sort)

    if page = opts.page or @get('page')
      params.page = page if page > 1

    Util.buildQuery(params) unless _.isEmpty(params)

  toString: (opts = {}) =>
    if query = @toQuery(opts)
      "?#{query}"
    else
      ''

module.exports = Query
