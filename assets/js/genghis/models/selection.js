define([
    'underscore', 'backbone', 'genghis/models', 'genghis/models/pagination', 'genghis/collections/servers',
    'genghis/models/server', 'genghis/collections/databases', 'genghis/models/database',
    'genghis/collections/collections', 'genghis/models/collection', 'genghis/collections/documents',
    'genghis/models/document', 'genghis/util', 'genghis/json'
], function(_, Backbone, Models, Pagination, Servers, Server, Databases, Database, Collections, Collection, Documents, Document, Util, GenghisJSON) {

    return Models.Selection = Backbone.Model.extend({

        defaults: {
            server:     null,
            database:   null,
            collection: null,
            query:      null,
            page:       null,
            explain:    false
        },

        initialize: function() {
            _.bindAll(this, 'select', 'update', 'nextPage', 'previousPage');
            this.bind('change', this.update);

            this.pagination        = new Pagination();

            this.servers           = new Servers();
            this.currentServer     = new Server();
            this.databases         = new Databases();
            this.currentDatabase   = new Database();
            this.collections       = new Collections();
            this.currentCollection = new Collection();
            this.documents         = new Documents();
            this.currentDocument   = new Document();
            this.explain           = new Document();
        },

        select: function(server, database, collection, documentId, query, page, explain) {
            this.set({
                server:     server     || null,
                database:   database   || null,
                collection: collection || null,
                document:   documentId || null,
                query:      query      || null,
                page:       page       || null,
                explain:    explain    || false
            });
        },

        update: function() {
            var server     = this.get('server');
            var database   = this.get('database');
            var collection = this.get('collection');
            var documentId = this.get('document');
            var query      = this.get('query');
            var page       = this.get('page');
            var explain    = this.get('explain');
            var url        = app.baseUrl;
            var params     = {};

            url = url + 'servers';
            this.servers.url = url;
            this.servers.fetch({reset: true, error: showErrorMessage});

            if (server) {
                url = url + '/' + encodeURIComponent(server);
                this.currentServer.url = url;
                this.currentServer.fetch({
                    reset: true,
                    error: fetchErrorHandler('databases', 'Server Not Found')
                });

                url = url + '/databases';
                this.databases.url = url;
                this.databases.fetch({reset: true, error: showErrorMessage});
            } else {
                this.currentServer.clear();
                this.databases.reset();
            }

            if (database) {
                url = url + '/' + encodeURIComponent(database);
                this.currentDatabase.url = url;
                this.currentDatabase.fetch({
                    reset: true,
                    error: fetchErrorHandler('collections', 'Database Not Found')
                });

                url = url + '/collections';
                this.collections.url = url;
                this.collections.fetch({reset: true, error: showErrorMessage});
            } else {
                this.currentDatabase.clear();
                this.collections.reset();
            }

            if (collection) {
                url = url + '/' + encodeURIComponent(collection);
                this.currentCollection.url = url;
                this.currentCollection.fetch({
                    reset: true,
                    error: fetchErrorHandler('documents', 'Collection Not Found')
                });

                var explainUrl = url + '/explain';
                url = url + '/documents';

                var urlQuery = '';
                if (query || page) {
                    if (query) params.q = encodeURIComponent(JSON.stringify(GenghisJSON.parse(query)));
                    if (page)  params.page = encodeURIComponent(page);
                    urlQuery = '?' + Util.buildQuery(params);
                }

                if (explain) {
                    this.explain.url = explainUrl + urlQuery;
                    this.explain.fetch({error: showErrorMessage});
                } else {
                    this.documents.url = url + urlQuery;
                    this.documents.fetch({reset: true, error: showErrorMessage});
                }
            } else {
                this.currentCollection.clear();
                this.documents.reset();
            }

            if (documentId) {
                this.currentDocument.clear({silent: true});
                this.currentDocument.id = documentId;
                this.currentDocument.urlRoot = url;
                this.currentDocument.fetch({
                    reset: true,
                    error: fetchErrorHandler(
                        'document',
                        'Document Not Found',
                        'But I&#146;m sure there are plenty of other nice documents out there&hellip;'
                    )
                });
            }

            function showErrorMessage(model, response) {
                if (response.status !== 404) {
                    try {
                        data = JSON.parse(response.responseText);
                    } catch (e) {
                        data = {};
                    }

                    app.alerts.create({
                        msg:   data.error || 'Unknown error',
                        level: 'error',
                        block: true
                    });
                }
            }

            function fetchErrorHandler(section, notFoundTitle, notFoundSubtitle) {
                notFoundTitle    = notFoundTitle    || 'Not Found';
                notFoundSubtitle = notFoundSubtitle || 'Please try again.';

                return function(model, response) {
                    switch (response.status) {
                        case 404:
                            // app.router.notFound(url + '/' + documentId);
                            app.showSection();
                            app.showMasthead(
                                '404: ' + notFoundTitle,
                                '<p>' + notFoundSubtitle + '</p>',
                                {error: true}
                            );
                            break;

                        default:
                            showErrorMessage(model, response);
                            break;
                    }
                };
            }

        },

        nextPage: function() {
            return 1 + (this.get('page') || 1);
        },

        previousPage: function() {
            return Math.max(1, (this.get('page') || 1) - 1);
        }
    });
});
