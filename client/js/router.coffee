{_, Backbone} = require './vendors'
Util          = require './util'

_e = encodeURIComponent

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
    'servers/:server/databases/:db/collections/:coll/documents':        'collectionSearch'
    'servers/:server/databases/:db/collections/:coll/explain':          'explain'
    'servers/:server/databases/:db/collections/:coll/documents/:docId': 'document'
    '*path':                                                            'notFound'

  index: ->
    @app.selection.select()

  redirectToIndex: ->
    @navigate('', true)

  server: (server) ->
    @app.selection.select(server)

  redirectToServer: (server) ->
    @navigate("servers/#{_e(server)}", true)

  database: (server, db) ->
    @app.selection.select(server, db)

  redirectToDatabase: (server, db) ->
    @navigate("servers/#{_e(server)}/databases/#{_e(db)}", true)

  collection: (server, db, coll) ->
    @app.selection.select(server, db, coll)

  redirectToCollection: (server, db, coll) ->
    @navigate("servers/#{_e(server)}/databases/#{_e(db)}/collections/#{_e(coll)}", true)

  collectionSearch: (server, db, coll) ->
    unless search = window.location.search
      return @redirectToCollection(server, db, coll)
    @app.selection.select(server, db, coll, null, search: search)

  redirectToCollectionSearch: (server, db, coll, search) ->
    return redirectToCollection(server, db, coll) unless search
    @navigate("servers/#{_e(server)}/databases/#{_e(db)}/collections/#{_e(coll)}/documents?#{search}", true)

  explain: (server, db, coll) ->
    search = window.location.search
    @app.selection.select(server, db, coll, null, search: search, explain: true)

  document: (server, db, coll, docId) ->
    @app.selection.select(server, db, coll, docId)

  redirectToDocument: (server, db, coll, docId) ->
    @navigate("/servers/#{_e(server)}/databases/#{_e(db)}/collections/#{_e(coll)}/documents/#{_e(docId)}", true)

  notFound: (path) ->
    @app.showNotFound()

module.exports = Router
