{_, Giraffe} = require '../vendors'
Util         = require '../util.coffee'
GenghisJSON  = require '../json.coffee'

stringify = (val) ->
  GenghisJSON.stringify(val, false)

class Search extends Giraffe.Model
  defaults:
    query:  {}
    fields: {}
    sort:   {}
    page:   1

  hasProjection: =>
    not _.isEmpty(@get('fields'))

  toParams: (opts = {}) =>
    params = {}
    if q = opts.query or @get('query')
      params.q = q unless _.isEmpty(q)
    if fields = opts.fields or @get('fields')
      params.fields = fields unless _.isEmpty(fields)
    if sort = opts.sort or @get('sort')
      params.sort = sort unless _.isEmpty(sort)
    if page = opts.page or @get('page')
      params.page = page if page > 1
    params

  toSearchString: (opts = {}) =>
    _j = if opts.pretty then stringify else JSON.stringify
    params = {}
    for own k, v of @toParams(opts)
      params[k] = _j(v)
    Util.buildSearch(params) unless _.isEmpty(params)

  toString: (opts = {}) =>
    if search = @toSearchString(opts)
      "?#{search}"
    else
      ''

  fromParams: (params = {}) =>
    sanitized = {}
    for own k, v of params
      switch k
        when 'q'
          sanitized.query = GenghisJSON.parse(v)
        when 'fields', 'sort'
          sanitized[k] = GenghisJSON.parse(v)
        when 'page'
          sanitized[k] = parseInt(v, 10)
    @set(_.defaults(sanitized, @defaults))

  fromString: (search = '') =>
    search = search[1..] if search[0] is '?'
    @fromParams(Util.parseSearch(search))

module.exports = Search
