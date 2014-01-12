{_, Giraffe} = require '../vendors'

Pagination  = require './pagination.coffee'
Servers     = require '../collections/servers.coffee'
Server      = require './server.coffee'
Databases   = require '../collections/databases.coffee'
Database    = require './database.coffee'
Collections = require '../collections/collections.coffee'
Collection  = require './collection.coffee'
Documents   = require '../collections/documents.coffee'
Document    = require './document.coffee'
Util        = require '../util.coffee'
GenghisJSON = require '../json'

SERVER_PARAMS     = ['server']
DATABASE_PARAMS   = ['server', 'database']
COLLECTION_PARAMS = ['server', 'database', 'collection']
DOCUMENTS_PARAMS  = ['server', 'database', 'collection', 'query', 'page', 'explain']
DOCUMENT_PARAMS   = ['server', 'database', 'collection', 'document']

class Selection extends Giraffe.Model
  defaults:
    server:     null
    database:   null
    collection: null
    query:      null
    page:       null
    document:   null
    explain:    false

  dataEvents:
    'change this': 'update'

  initialize: ->
    @pagination        = new Pagination()
    @servers           = new Servers()
    @currentServer     = new Server()
    @databases         = new Databases()
    @currentDatabase   = new Database()
    @collections       = new Collections()
    @currentCollection = new Collection()
    @documents         = new Documents()
    @currentDocument   = new Document()
    @explain           = new Document()

  select: (
    server = null,
    database = null,
    collection = null,
    documentId = null,
    query = null,
    page = null,
    explain = false
  ) =>
    @set({server, database, collection, document: documentId, query, page, explain})

  buildUrl: (type) =>
    e = (prop) =>
      encodeURIComponent @get(prop)

    switch type
      when "documents", "explain"
        params = {}
        params.q    = encodeURIComponent(JSON.stringify(GenghisJSON.parse(@get('query')))) if @has('query')
        params.page = e('page') if @has('page')
        urlQuery = if _.isEmpty(params) then '' else "?#{Util.buildQuery(params)}"
        "#{@baseUrl}servers/#{e 'server'}/databases/#{e 'database'}/collections/#{e 'collection'}/#{type}#{urlQuery}"
      when "collection"
        "#{@baseUrl}servers/#{e 'server'}/databases/#{e 'database'}/collections/#{e 'collection'}"
      when "collections"
        "#{@baseUrl}servers/#{e 'server'}/databases/#{e 'database'}/collections"
      when "database"
        "#{@baseUrl}servers/#{e 'server'}/databases/#{e 'database'}"
      when "databases"
        "#{@baseUrl}servers/#{e 'server'}/databases"
      when "server"
        "#{@baseUrl}servers/#{e 'server'}"
      when "servers"
        "#{@baseUrl}servers"
      else
        throw new Error("Unknown URL type: #{type}")

  update: =>
    showErrorMessage = (model, response = {}) ->
      return if response.status is 404
      try
        data = JSON.parse(response.responseText)
      app.alerts.add(msg: data?.error or 'Unknown error', level: 'danger', block: true)

    fetchErrorHandler = (section, notFoundHeading = 'Not Found', notFoundContent = '<p>Please try again.</p>') ->
      (model, response) ->
        switch response.status
          when 404
            app.showNotFound(notFoundHeading, notFoundContent)
          else
            showErrorMessage(model, response)

    changed = @changedAttributes()

    @servers.url = @buildUrl('servers')
    # TODO: fetch servers less often.
    @servers.fetch(reset: true)
      .fail(showErrorMessage)

    if @has('server') and not _.isEmpty(_.pick(changed, SERVER_PARAMS))
      @currentServer.url = @buildUrl('server')
      @currentServer.fetch(reset: true)
        .fail(fetchErrorHandler('databases', 'Server Not Found'))

      @databases.url = @buildUrl('databases')
      @databases.fetch(reset: true)
        .fail(showErrorMessage)

    if @has('database') and not _.isEmpty(_.pick(changed, DATABASE_PARAMS))
      @currentDatabase.url = @buildUrl('database')
      @currentDatabase.fetch(reset: true)
        .fail(fetchErrorHandler('collections', 'Database Not Found'))

      @collections.url = @buildUrl('collections')
      @collections.fetch(reset: true)
        .fail(showErrorMessage)

    if @has('collection') and not _.isEmpty(_.pick(changed, COLLECTION_PARAMS))
      @currentCollection.url = @buildUrl('collection')
      @currentCollection.fetch(reset: true)
        .fail(fetchErrorHandler('documents', 'Collection Not Found'))

    if @has('collection') and not _.isEmpty(_.pick(changed, DOCUMENTS_PARAMS))
      @documents.url = @buildUrl('documents')
      @documents.fetch(reset: true)
        .fail(showErrorMessage)

    if @has('document') and not _.isEmpty(_.pick(changed, DOCUMENT_PARAMS))
      @currentDocument.clear silent: true
      @currentDocument.id      = @get('document')
      @currentDocument.urlRoot = @buildUrl('documents')
      @currentDocument.fetch(reset: true)
        .fail(fetchErrorHandler(
          'document',
          'Document Not Found',
          '<p>But I&#146;m sure there are plenty of other nice documents out there&hellip;</p>'
        ))

    if @get('explain')
      @explain.url = @buildUrl('explain')
      @explain.fetch()
        .fail(showErrorMessage)

  nextPage: =>
    1 + (@get('page') or 1)

  previousPage: =>
    Math.max(1, (@get('page') or 1) - 1)

module.exports = Selection
