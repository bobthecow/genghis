{_}         = require '../vendors'
View        = require './view'
CustomSort  = require './sort_custom'
Search      = require '../models/search'
GenghisJSON = require '../json'
Util        = require '../util'
template    = require('../../templates/sort.mustache').render

class Sort extends View
  className: 'sort-form form-inline'

  attributes:
    role: 'form'

  template: template

  events:
    'click a.sort-link': 'navigate'
    'click a.custom':    'customSort'

  dataEvents:
    'change:sort model': 'render'

  serialize: =>
    sort   = @model.get('sort')
    base   = @collection.baseUrl()
    search = @model.toString
    urlFor = (sort) -> "#{base}#{search(sort: sort)}"

    sort:  if _.isEmpty(sort) then 'natural' else GenghisJSON.stringify(sort, false)
    sorts: _.map(@indexedSorts(), (s) ->
      name: GenghisJSON.prettyPrint(s)
      url:  urlFor(s)
    )
    naturalUrl: urlFor({})

  afterRender: =>
    @$('.dropdown-toggle').dropdown()

  navigate: (e) ->
    e.preventDefault()
    $target = $(e.target)
    $target = $target.parents('.sort-link') unless $target.hasClass('sort-link')
    if url = $target.attr('href')
      app.router.navigate(Util.route(url), true)

  customSort: (e) =>
    e.preventDefault()

    model = new Search(sort: @model.get('sort'))
    model.on('change:sort', =>
      base   = @collection.baseUrl()
      search = @model.toString(sort: model.get('sort'))
      app.router.navigate(Util.route("#{base}#{search}"), true)
    )

    view = new CustomSort(model: model)
    view.on('detached', @render)
    @attach(view, method: 'html')

  # TODO: fill out the sorts with these...
  indexedSorts: =>
    indexes = @collection.coll.get('indexes') || []
    _.uniq(_.map(indexes, (index) ->
      _.object([_.first(_.keys(index.key))], [1])
    ))

module.exports = Sort
