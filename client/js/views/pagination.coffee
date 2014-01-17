{$, _}   = require '../vendors'
View     = require './view.coffee'
Util     = require '../util.coffee'
template = require '../../templates/pagination.mustache'

class Pagination extends View
  template: template

  ui:
    '$next': 'li.next a[href]'
    '$prev': 'li.prev a[href]'

  events:
    'click a': 'navigate'

  keyboardEvents:
    'n': 'nextPage'
    'p': 'prevPage'

  dataEvents:
    'change query':      'render'
    'change pagination': 'render'

  initialize: ->
    @pagination = @collection.pagination
    @query      = @collection.query
    super

  serialize: ->
    count = 9
    half  = Math.ceil(count / 2)
    page  = @pagination.get('page')
    pages = @pagination.get('pages')
    min   = (if (page > half) then Math.max(page - (half - 3), 1) else 1)
    max   = (if (pages - page > half) then Math.min(page + (half - 3), pages) else pages)
    start = (if (max is pages) then Math.max(pages - (count - 3), 1) else min)
    end   = (if (min is 1) then Math.min(start + (count - 3), pages) else max)
    end   = pages if end >= pages - 2
    start = 1  if start <= 3
    url   = @urlTemplate

    page:     page
    last:     pages
    firstUrl: url(1)
    prevUrl:  url(Math.max(1, page - 1))
    nextUrl:  url(Math.min(page + 1, pages))
    lastUrl:  url(pages)
    pageUrls: _.range(start, end + 1).map((i) ->
      index: i
      url: url(i)
      active: i is page
    )
    isFirst:  page is 1
    isStart:  start is 1
    isEnd:    end >= pages
    isLast:   page is pages

  afterRender: ->
    @$el.toggle @pagination.get('pages') > 1

  urlTemplate: (i) =>
    base  = @collection.baseUrl()
    query = @query.toString(page: i)
    "#{base}#{query}"

  navigate: (e) ->
    e.preventDefault()
    url = $(e.target).attr('href')
    app.router.navigate Util.route(url), true if url

  nextPage: (e) =>
    # TODO: bind/unbind mousetrap so we don't have to check visibilty?
    if @$el.is(':visible')
      e.preventDefault()
      @$next.click()

  prevPage: (e) =>
    if @$el.is(':visible')
      e.preventDefault()
      @$prev.click()

module.exports = Pagination
