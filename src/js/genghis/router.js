Genghis.Router = Backbone.Router.extend({
    routes: {
        '':                                                                                  'index',
        'servers':                                                                           'redirectToIndex',
        'servers/:server':                                                                   'server',
        'servers/:server/databases':                                                         'redirectToServer',
        'servers/:server/databases/:database':                                               'database',
        'servers/:server/databases/:database/collections':                                   'redirectToDatabase',
        'servers/:server/databases/:database/collections/:collection':                       'collection',
        'servers/:server/databases/:database/collections/:collection/documents':             'redirectToCollection',
        'servers/:server/databases/:database/collections/:collection/documents?*query':      'collectionQuery',
        'servers/:server/databases/:database/collections/:collection/documents/:documentId': 'document',
        '*path':                                                                             'notFound'
    },
    index: function() {
        document.title = 'Genghis';
        Genghis.Selection.select();
        App.showSection('servers');
    },
    redirectToIndex: function() {
        this.navigate('', true);
    },
    server: function(server) {
        document.title = this.buildTitle(server)
        Genghis.Selection.select(server);
        App.showSection('databases');
    },
    redirectToServer: function(server) {
        this.navigate('servers/'+server, true);
    },
    database: function(server, database) {
        document.title = this.buildTitle(server, database)
        Genghis.Selection.select(server, database);
        App.showSection('collections');
    },
    redirectToDatabase: function(server, database) {
        this.navigate('servers/'+server+'/databases/'+database, true);
    },
    collection: function(server, database, collection) {
        document.title = this.buildTitle(server, database, collection)
        Genghis.Selection.select(server, database, collection);
        App.showSection('documents');
    },
    redirectToCollection: function(server, database, collection) {
        this.navigate('servers/'+server+'/databases/'+database+'/collections/'+collection, true);
    },
    collectionQuery: function(server, database, collection, query) {
        document.title = this.buildTitle(server, database, collection, 'Query results');
        var params = Genghis.Util.parseQuery(query);
        Genghis.Selection.select(server, database, collection, null, params.q, params.page);
        App.showSection('documents');
    },
    document: function(server, database, collection, documentId) {
        document.title = this.buildTitle(server, database, collection, documentId);
        Genghis.Selection.select(server, database, collection, documentId);
        App.showSection('document');
    },
    redirectToDocument: function(server, database, collection, document) {
        this.navigate('servers/'+server+'/databases/'+database+'/collections/'+collection+'/documents/'+document, true);
    },
    notFound: function(path) {
        // fix a weird case where the Backbone router won't route if the root url == the current pathname.
        if (path.replace(/\/$/, '') == Genghis.baseUrl.replace(/\/$/, '')) return App.Router.navigate('', true);

        document.title = this.buildTitle('404: Not Found');
        $('section#genghis section#error').html("<header><h2>404: Not Found</h2></header><p>If you think you've reached this message in error, please press <strong>0</strong> to speak with an operator. Otherwise, hang up and try again.</p>");
        App.showSection('error');
    },
    buildTitle: function() {
        var args = Array.prototype.slice.call(arguments);
        return (args.length) ? 'Genghis \u2014 ' + args.join(' \u203A ') : 'Genghis';
    }
});
