{_, Backbone} = require './vendors'
Util          = require './util.coffee'

_e = encodeURIComponent

getParams = ->
  return {} unless document.location.search
  Util.parseQuery window.location.search.substr(1)

getQuery = ->
  getParams().q

class Router extends Backbone.Router
  initialize: (options) ->
    @app = options.app

  routes:
    '':                                                                 'index'
    'servers':                                                          'redirectToIndex'
    'servers/:server':                                                  'server'
    'servers/:server/databases':                                        'redirectToServer'
    'servers/:server/databases/:db':                                    'database'
    'servers/:server/databases/:db/collections':                        'redirectToDatabase'
    'servers/:server/databases/:db/collections/:coll':                  'collection'
    'servers/:server/databases/:db/collections/:coll/documents':        'collectionQuery'
    'servers/:server/databases/:db/collections/:coll/documents?*query': 'collectionQuery'
    'servers/:server/databases/:db/collections/:coll/explain':          'explainQuery'
    'servers/:server/databases/:db/collections/:coll/explain?*query':   'explainQuery'
    'servers/:server/databases/:db/collections/:coll/documents/:docId': 'document'
    '*path':                                                            'notFound'

  index: ->
    @app.selection.select()

  indexRoute: ->
    ''

  redirectToIndex: ->
    @navigate(@indexRoute(), true)

  server: (server) ->
    @app.selection.select(server)

  serverRoute: (server) ->
    "servers/#{_e(server)}"

  redirectToServer: (server) ->
    @navigate(@serverRoute(server), true)

  database: (server, db) ->
    @app.selection.select(server, db)

  databaseRoute: (server, db) ->
    "servers/#{_e(server)}/databases/#{_e(db)}"

  redirectToDatabase: (server, db) ->
    @navigate(@databaseRoute(server, db), true)

  collection: (server, db, coll) ->
    return @redirectToQuery(server, db, coll, getQuery()) if window.location.search
    @app.selection.select(server, db, coll)

  collectionRoute: (server, db, coll) ->
    "servers/#{_e(server)}/databases/#{_e(db)}/collections/#{_e(coll)}"

  redirectToCollection: (server, db, coll) ->
    @navigate(@collectionRoute(server, db, coll), true)

  collectionQuery: (server, db, coll) ->
    return @redirectToCollection(server, db, coll) unless window.location.search
    params = getParams()
    @app.selection.select(server, db, coll, null, query: params.q, page: params.page)

  collectionQueryRoute: (server, db, coll, query) ->
    queryString = Util.buildQuery(q: e(query))
    "servers/#{_e(server)}/databases/#{_e(db)}/collections/#{_e(coll)}/documents?#{queryString}"

  redirectToCollectionQuery: (server, db, coll, query) ->
    @navigate(@collectionQueryRoute(server, db, coll, query or getQuery()), true)

  explainQuery: (server, db, coll) ->
    @app.selection.select(server, db, coll, null, query: getQuery(), explain: true)

  document: (server, db, coll, docId) ->
    @app.selection.select(server, db, coll, docId)

  documentRoute: (server, db, coll, docId) ->
    "/servers/#{_e(server)}/databases/#{_e(db)}/collections/#{_e(coll)}/documents/#{_e(docId)}"

  redirectToDocument: (server, db, coll, docId) ->
    @navigate(@documentRoute(server, db, coll, docId), true)

  redirectTo: (server, db, coll, docId, query) ->
    return @redirectToIndex()              unless server
    return @redirectToServer(server)       unless db
    return @redirectToDatabase(server, db) unless coll

    if not docId and not query
      @redirectToCollection(server, db, coll)
    else unless query
      @redirectToDocument(server, db, coll, docId)
    else
      @redirectToCollectionQuery(server, db, coll, query)

  notFound: (path) ->
    @app.showNotFound()

module.exports = Router
