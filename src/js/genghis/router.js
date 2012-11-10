Genghis.Router = Backbone.Router.extend({
    routes: {
        '':                                                                                  'index',
        'servers':                                                                           'redirectToIndex',
        'servers/:server':                                                                   'server',
        'servers/:server/databases':                                                         'redirectToServer',
        'servers/:server/databases/:database':                                               'database',
        'servers/:server/databases/:database/collections':                                   'redirectToDatabase',
        'servers/:server/databases/:database/collections/:collection?*query':                'redirectToCollectionQuery',
        'servers/:server/databases/:database/collections/:collection':                       'collection',
        'servers/:server/databases/:database/collections/:collection/documents':             'redirectToCollection',
        'servers/:server/databases/:database/collections/:collection/documents?*query':      'collectionQuery',
        'servers/:server/databases/:database/collections/:collection/documents/:documentId': 'document',
        '*path':                                                                             'notFound'
    },
    index: function() {
        document.title = 'Genghis';
        app.selection.select();
        app.showSection('servers');
    },
    redirectToIndex: function() {
        this.navigate('', true);
    },
    server: function(server) {
        document.title = this.buildTitle(server);
        app.selection.select(server);
        app.showSection('databases');
    },
    redirectToServer: function(server) {
        this.navigate('servers/'+server, true);
    },
    database: function(server, database) {
        document.title = this.buildTitle(server, database);
        app.selection.select(server, database);
        app.showSection('collections');
    },
    redirectToDatabase: function(server, database) {
        this.navigate('servers/'+server+'/databases/'+database, true);
    },
    collection: function(server, database, collection) {
        document.title = this.buildTitle(server, database, collection);
        app.selection.select(server, database, collection);
        app.showSection('documents');
    },
    redirectToCollection: function(server, database, collection) {
        this.navigate('servers/'+server+'/databases/'+database+'/collections/'+collection, true);
    },
    redirectToCollectionQuery: function(server, database, collection, query) {
        this.navigate('servers/'+server+'/databases/'+database+'/collections/'+collection+'/documents?'+query, true);
    },
    collectionQuery: function(server, database, collection, query) {
        document.title = this.buildTitle(server, database, collection, 'Query results');
        var params = Genghis.Util.parseQuery(query);
        app.selection.select(server, database, collection, null, params.q, params.page);
        app.showSection('documents');
    },
    redirectToQuery: function(server, database, collection, query) {
        this.navigate('servers/'+server+'/databases/'+database+'/collections/'+collection+'/documents?'+Genghis.Util.buildQuery({q: encodeURIComponent(query)}), true);
    },
    document: function(server, database, collection, documentId) {
        document.title = this.buildTitle(server, database, collection, decodeURIComponent(documentId));
        app.selection.select(server, database, collection, decodeURIComponent(documentId));
        app.showSection('document');
    },
    redirectToDocument: function(server, database, collection, document) {
        this.navigate('servers/'+server+'/databases/'+database+'/collections/'+collection+'/documents/'+document, true);
    },
    redirectTo: function(server, database, collection, document, query) {
        if (!server)     return this.redirectToIndex();
        if (!database)   return this.redirectToServer(server);
        if (!collection) return this.redirectToDatabase(server, database);

        if (!document && !query) {
            return this.redirectToCollection(server, database, collection);
        } else if (!query) {
            return this.redirectToDocument(server, database, collection, document);
        } else {
            return this.redirectToQuery(server, database, collection, query);
        }
    },
    notFound: function(path) {
        // fix a weird case where the Backbone router won't route if the root url == the current pathname.
        if (path.replace(/(^\/|\/$)/g, '') == app.baseUrl.replace(/(^\/|\/$)/g, '')) return this.redirectToIndex();

        document.title = this.buildTitle('404: Not Found');
        app.showSection();
        app.showMasthead('404: Not Found', "<p>If you think you've reached this message in error, please press <strong>0</strong> to speak with an operator. Otherwise, hang up and try again.</p>", {
            error: true,
            epic:  true
        });
    },
    buildTitle: function() {
        var args = Array.prototype.slice.call(arguments);
        return (args.length) ? 'Genghis \u2014 ' + args.join(' \u203A ') : 'Genghis';
    }
});
