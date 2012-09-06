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

        this.pagination        = new Genghis.Models.Pagination;

        this.servers           = new Genghis.Collections.Servers;
        this.currentServer     = new Genghis.Models.Server;
        this.databases         = new Genghis.Collections.Databases;
        this.currentDatabase   = new Genghis.Models.Database;
        this.collections       = new Genghis.Collections.Collections;
        this.currentCollection = new Genghis.Models.Collection;
        this.documents         = new Genghis.Collections.Documents;
        this.currentDocument   = new Genghis.Models.Document;
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
        var url        = app.baseUrl;
        var params     = {};

        url = url + 'servers';
        this.servers.url = url;
        this.servers.fetch();

        if (server) {
            url = url + '/' + server;
            this.currentServer.url = url;
            this.currentServer.fetch();

            url = url + '/databases';
            this.databases.url = url;
            this.databases.fetch();
        } else {
            this.currentServer.clear();
            this.databases.reset();
        }

        if (database) {
            url = url + '/' + database;
            this.currentDatabase.url = url;
            this.currentDatabase.fetch();

            url = url + '/collections';
            this.collections.url = url;
            this.collections.fetch();
        } else {
            this.currentDatabase.clear();
            this.collections.reset();
        }

        if (collection) {
            url = url + '/' + collection;
            this.currentCollection.url = url;
            this.currentCollection.fetch();

            url = url + '/documents';

            var url_query = '';
            if (query || page) {
                if (query) params.q = encodeURIComponent(JSON.stringify(Genghis.JSON.parse(query)));
                if (page)  params.page = encodeURIComponent(page);
                url_query = '?' + Genghis.Util.buildQuery(params);
            }

            this.documents.url = url + url_query;
            this.documents.fetch();
        } else {
            this.currentCollection.clear();
            this.documents.reset();
        }

        if (documentId) {
            this.currentDocument.clear({silent: true});
            this.currentDocument.id = documentId;
            this.currentDocument.urlRoot = url;
            this.currentDocument.fetch();
        }
    },
    nextPage: function() {
        return 1 + (this.get('page') || 1);
    },
    previousPage: function() {
        return Math.max(1, (this.get('page') || 1) - 1);
    }
});
