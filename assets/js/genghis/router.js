define(['backbone-stack', 'genghis'], function(Backbone, Genghis) {
    var e = encodeURIComponent;

    return Genghis.Router = Backbone.Router.extend({
        initialize: function(options) {
            this.app = options.app;
        },

        routes: {
            '':                                                                                  'index',
            'servers':                                                                           'redirectToIndex',
            'servers/:server':                                                                   'server',
            'servers/:server/databases':                                                         'redirectToServer',
            'servers/:server/databases/:database':                                               'database',
            'servers/:server/databases/:database/collections':                                   'redirectToDatabase',
            'servers/:server/databases/:database/collections/:collection':                       'collection',
            'servers/:server/databases/:database/collections/:collection/documents':             'collectionQueryOrRedirect',
            'servers/:server/databases/:database/collections/:collection/documents?*query':      'collectionQueryOrRedirect',
            'servers/:server/databases/:database/collections/:collection/explain':               'explainQuery',
            'servers/:server/databases/:database/collections/:collection/explain?*query':        'explainQuery',
            'servers/:server/databases/:database/collections/:collection/documents/:documentId': 'document',
            '*path':                                                                             'notFound'
        },

        index: function() {
            this.app.selection.select();
            this.app.showSection('servers');
        },

        redirectToIndex: function() {
            this.navigate('', true);
        },

        server: function(server) {
            this.app.selection.select(server);
            this.app.showSection('databases');
        },

        redirectToServer: function(server) {
            this.navigate('servers/' + e(server), true);
        },

        database: function(server, database) {
            this.app.selection.select(server, database);
            this.app.showSection('collections');
        },

        redirectToDatabase: function(server, database) {
            this.navigate('servers/' + e(server) + '/databases/' + e(database), true);
        },

        collection: function(server, database, collection) {
            if (!!window.location.search) {
                return this.collectionQueryOrRedirect(server, database, collection);
            }

            this.app.selection.select(server, database, collection);
            this.app.showSection('documents');
        },

        redirectToCollection: function(server, database, collection) {
            this.navigate('servers/' + e(server) + '/databases/' + e(database) + '/collections/' + e(collection), true);
        },

        collectionQueryOrRedirect: function(server, database, collection) {
            if (!!window.location.search) {
                return this.collectionQuery(server, database, collection, window.location.search.substr(1));
            } else {
                this.redirectToCollection(server, database, collection);
            }
        },

        collectionQuery: function(server, database, collection, query) {
            var params = Genghis.Util.parseQuery(query);
            this.app.selection.select(server, database, collection, null, params.q, params.page);
            this.app.showSection('documents');
        },

        redirectToQuery: function(server, database, collection, query) {
            this.navigate('servers/' + e(server) + '/databases/' + e(database) + '/collections/' + e(collection) + '/documents?' + Genghis.Util.buildQuery({q: e(query)}), true);
        },

        explainQuery: function(server, database, collection) {
            var query = window.location.search.substr(1);
            var params = Genghis.Util.parseQuery(query);
            this.app.selection.select(server, database, collection, null, params.q, null, true);
            this.app.showSection('explain');
        },

        document: function(server, database, collection, documentId) {
            this.app.selection.select(server, database, collection, documentId);
            this.app.showSection('document');
        },

        redirectToDocument: function(server, database, collection, documentId) {
            var e = encodeURIComponent;
            this.navigate('servers/' + e(server) + '/databases/' + e(database) + '/collections/' + e(collection) + '/documents/' + e(documentId), true);
        },

        redirectTo: function(server, database, collection, documentId, query) {
            if (!server)     return this.redirectToIndex();
            if (!database)   return this.redirectToServer(server);
            if (!collection) return this.redirectToDatabase(server, database);

            if (!documentId && !query) {
                return this.redirectToCollection(server, database, collection);
            } else if (!query) {
                return this.redirectToDocument(server, database, collection, documentId);
            } else {
                return this.redirectToQuery(server, database, collection, query);
            }
        },

        notFound: function(path) {
            this.app.showSection();
            this.app.showMasthead('404: Not Found', "<p>If you think you've reached this message in error, please press <strong>0</strong> to speak with an operator. Otherwise, hang up and try again.</p>", {
                error: true,
                epic:  true
            });
        }
    });
});
