{_, Giraffe} = require '../vendors'

Pagination  = require './pagination'
Servers     = require '../collections/servers'
Server      = require './server'
Database    = require './database'
Collection  = require './collection'
Document    = require './document'
Explain     = require './explain'
Util        = require '../util'
GenghisJSON = require '../json'

SERVER_PARAMS     = ['server']
DATABASE_PARAMS   = ['server', 'database']
COLLECTION_PARAMS = ['server', 'database', 'collection']
DOCUMENTS_PARAMS  = ['server', 'database', 'collection', 'search', 'explain']
DOCUMENT_PARAMS   = ['server', 'database', 'collection', 'document']
SEARCH_PARAMS     = ['search']

class Selection extends Giraffe.Model
  defaults:
    # Current selection
    server:     null
    database:   null
    collection: null
    document:   null

    # URL search params
    search:     null

    # Explain flag
    # TODO: this might not be a good model for the concept. Revisit.
    explain:    false

  dataEvents:
    'change this':   'update'
    'change search': 'update'

  initialize: ->
    @servers             = new Servers()
    @servers.url         = "#{@baseUrl}servers"
    @server              = new Server()
    @server.collection   = @servers
    @databases           = @server.databases
    @database            = new Database()
    @database.collection = @databases
    @collections         = @database.collections
    @coll                = new Collection()
    @coll.collection     = @collections
    @documents           = @coll.documents
    @search              = @documents.search
    @document            = new Document()
    @document.collection = @documents
    @explain             = new Explain()
    @explain.search      = @search
    @explain.coll        = @coll

  select: (server = null, database = null, collection = null, doc = null, opts = {}) =>
    @set(_.extend(
      {server, database, collection, document: doc, search: null},
      _.pick(opts, 'search', 'explain')
    ))

  current: =>
    return 'servers'     unless @has('server')
    return 'databases'   unless @has('database')
    return 'collections' unless @has('collection')
    return 'explain'     if @get('explain')
    return 'documents'   unless @has('document')
    'document'

  update: =>
    showError = (model, response = {}) ->
      return if response.status is 404
      try
        data = JSON.parse(response.responseText)
      app.alerts.add(msg: data?.error or 'Unknown error', level: 'danger', block: true)

    handleError = (section, notFoundHead = 'Not Found', notFoundContent = '<p>Please try again.</p>') ->
      (model, response) ->
        switch response.status
          when 404
            app.showNotFound(notFoundHead, notFoundContent)
          else
            showError(model, response)

    changed = @changedAttributes()
    current = @current()

    if @servers.length is 0 or current is 'servers'
      @servers.fetch(reset: true)
        .fail(showError)

    if @has('server')
      if current is 'databases' or not _.isEmpty(_.pick(changed, SERVER_PARAMS))
        @server.id = @get('server')
        @server.set(@server.idAttribute, @server.id)
        @server.fetch(reset: true)
          .fail(handleError('databases', 'Server Not Found'))

    if @has('database')
      if current is 'collections' or not _.isEmpty(_.pick(changed, DATABASE_PARAMS))
        @database.id = @get('database')
        @database.set(@database.idAttribute, @database.id)
        @database.fetch(reset: true)
          .fail(handleError('collections', 'Database Not Found'))

    # Get search params out of the way before updating the collection or explain...
    unless _.isEmpty(_.pick(changed || {}, SEARCH_PARAMS))
      @search.fromString(@get('search') || '')

    if @has('collection') and current isnt 'explain'
      if current is 'documents' or not _.isEmpty(_.pick(changed, COLLECTION_PARAMS))
        @coll.id = @get('collection')
        @coll.set(@coll.idAttribute, @coll.id)
        @coll.fetch(reset: true)
          .fail(handleError('documents', 'Collection Not Found'))

    if @has('document')
      if current is 'document' or not _.isEmpty(_.pick(changed, DOCUMENT_PARAMS))
        @document.id = @get('document')
        @document.fetch(reset: true)
          .fail(handleError(
            'document',
            'Document Not Found',
            '<p>But I&#146;m sure there are plenty of other nice documents out there&hellip;</p>'
          ))

    if @get('explain')
      @explain.fetch()
        .fail(showError)

module.exports = Selection
