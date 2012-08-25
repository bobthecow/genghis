Genghis.Models.Selection = Backbone.Model.extend({
    defaults: {
        server:     null,
        database:   null,
        collection: null,
        query:      null,
        page:       null
    },
    initialize: function() {
        _.bindAll(this, 'select', 'update', 'nextPage', 'previousPage');
        this.bind('change', this.update);

        this.Pagination        = new Genghis.Models.Pagination;

        this.Servers           = new Genghis.Collections.Servers;
        this.CurrentServer     = new Genghis.Models.Server;
        this.Databases         = new Genghis.Collections.Databases;
        this.CurrentDatabase   = new Genghis.Models.Database;
        this.Collections       = new Genghis.Collections.Collections;
        this.CurrentCollection = new Genghis.Models.Collection;
        this.Documents         = new Genghis.Collections.Documents;
        this.CurrentDocument   = new Genghis.Models.Document;
    },
    select: function(server, database, collection, documentId, query, page) {
        this.set({
            server:     server     || null,
            database:   database   || null,
            collection: collection || null,
            document:   documentId || null,
            query:      query      || null,
            page:       page       || null
        });
    },
    update: function() {
        var server     = this.get('server');
        var database   = this.get('database');
        var collection = this.get('collection');
        var documentId = this.get('document');
        var query      = this.get('query');
        var page       = this.get('page');
        var url        = Genghis.baseUrl;
        var params     = {};

        url = url + 'servers';
        this.Servers.url = url;
        this.Servers.fetch();

        if (server) {
            url = url + '/' + server;
            this.CurrentServer.url = url;
            this.CurrentServer.fetch();

            url = url + '/databases';
            this.Databases.url = url;
            this.Databases.fetch();
        } else {
            this.CurrentServer.clear();
            this.Databases.reset();
        }

        if (database) {
            url = url + '/' + database;
            this.CurrentDatabase.url = url;
            this.CurrentDatabase.fetch();

            url = url + '/collections';
            this.Collections.url = url;
            this.Collections.fetch();
        } else {
            this.CurrentDatabase.clear();
            this.Collections.reset();
        }

        if (collection) {
            url = url + '/' + collection;
            this.CurrentCollection.url = url;
            this.CurrentCollection.fetch();

            url = url + '/documents';

            var url_query = '';
            if (query || page) {
                if (query) params.q = encodeURIComponent(query);
                if (page)  params.page = encodeURIComponent(page);
                url_query = '?' + Genghis.Util.buildQuery(params);
            }

            this.Documents.url = url + url_query;
            this.Documents.fetch();
        } else {
            this.CurrentCollection.clear();
            this.Documents.reset();
        }

        if (documentId) {
            this.CurrentDocument.clear({silent: true});
            this.CurrentDocument.id = documentId;
            this.CurrentDocument.urlRoot = url;
            this.CurrentDocument.fetch();
        }
    },
    nextPage: function() {
        return 1 + (this.get('page') || 1);
    },
    previousPage: function() {
        return Math.max(1, (this.get('page') || 1) - 1);
    }
});
