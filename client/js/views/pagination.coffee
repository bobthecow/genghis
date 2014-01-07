$        = require 'jquery'
_        = require 'underscore'
View     = require './view.coffee'
Util     = require '../util.coffee'
template = require 'hgn!genghis/templates/pagination'

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

  modelEvents:
    'change': 'render'

  serialize: ->
    count = 9
    half  = Math.ceil(count / 2)
    page  = @model.get("page")
    pages = @model.get("pages")
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
    @$el.toggle @model.get('pages') > 1

  urlTemplate: (i) =>
    url    = @collection.url
    chunks = url.split('?')
    base   = chunks.shift()
    params = Util.parseQuery(chunks.join('?'))
    extra  = {page: i}

    # TODO: this is ugly. fix it.

    # swap out the query for a pretty one
    extra.q = encodeURIComponent(app.selection.get('query')) if params.q
    queryString = Util.buildQuery(_.extend(params, extra))
    "#{base}?#{queryString}"

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
