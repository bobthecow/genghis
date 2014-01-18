{_, Giraffe} = require '../vendors'
Document     = require '../models/document.coffee'
Search       = require '../models/search.coffee'
Pagination   = require '../models/pagination.coffee'

isGuessable = (d) ->
  id = d._id or null

  # Handle the trivial cases...

  # non-object ids shouldn't count against it
  return true unless _.isObject(id) and id.$genghisType is 'ObjectId'
  # object ids with the wrong length string should
  return false unless id.$value.length is 24

  timestamp = parseInt(id.$value[0..7], 16) * 1000

  # If it's too far in the past or future, don't guess creation time.
  @end > timestamp > @start

class Documents extends Giraffe.Collection
  model: Document

  dataEvents:
    'change search':  'fetchReset'
    'change:id coll': 'fetchReset'

  initialize: ->
    @search     = new Search()
    @pagination = new Pagination()
    # @pagination.search = @search
    super

  fetchReset: =>
    return unless @coll.id # WTF?
    @fetch(reset: true)

  baseUrl: =>
    "#{_.result(@coll, 'url')}/documents"

  url: (opts = {}) =>
    base   = @baseUrl()
    search = @search.toString(_.extend({pretty: false}, opts))
    "#{base}#{search}"

  parse: (resp) ->
    @pagination.set
      page:  resp.page
      pages: resp.pages
      count: resp.documents.length
      total: resp.count

    @guessCreationTime = _.all(resp.documents, isGuessable,
      start: 1251388342000                                    # MongoDB v1.0 release date
      end: (new Date()).getTime() + (2 * 24 * 60 * 60 * 1000) # within the next 48 hours
    )

    resp.documents

module.exports = Documents
