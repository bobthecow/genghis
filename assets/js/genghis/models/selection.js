define([
    'underscore', 'backbone.giraffe', 'genghis/models', 'genghis/models/pagination', 'genghis/collections/servers',
    'genghis/models/server', 'genghis/collections/databases', 'genghis/models/database',
    'genghis/collections/collections', 'genghis/models/collection', 'genghis/collections/documents',
    'genghis/models/document', 'genghis/util', 'genghis/json'
], function(_, Giraffe, Models, Pagination, Servers, Server, Databases, Database, Collections, Collection, Documents, Document, Util, GenghisJSON) {

    var SERVER_PARAMS     = ['server'];
    var DATABASE_PARAMS   = ['server', 'database'];
    var COLLECTION_PARAMS = ['server', 'database', 'collection'];
    var DOCUMENTS_PARAMS  = ['server', 'database', 'collection', 'query', 'page', 'explain'];
    var DOCUMENT_PARAMS   = ['server', 'database', 'collection', 'document'];

    return Models.Selection = Giraffe.Model.extend({

        defaults: {
            server:     null,
            database:   null,
            collection: null,
            query:      null,
            page:       null,
            document:   null,
            explain:    false
        },

        initialize: function() {
            _.bindAll(this, 'select', 'buildUrl', 'update', 'nextPage', 'previousPage');

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

        buildUrl: function(type) {
            var url  = [];
            var that = this;
            var e    = function(prop) {
                return encodeURIComponent(that.get(prop));
            };
            var urlQuery = '';

            switch(type) {
                // yes, the breaks are intentionally left out:
                case 'documents':
                case 'explain':
                    url.unshift(type);
                    var params = {};
                    if (this.has('query')) {
                        params.q = encodeURIComponent(JSON.stringify(GenghisJSON.parse(this.get('query'))));
                    }
                    if (this.has('page')) {
                        params.page = encodeURIComponent(this.get('page'));
                    }
                    if (!_.isEmpty(params)) {
                        urlQuery = '?' + Util.buildQuery(params);
                    }
                case 'collection':
                    url.unshift(e('collection'));
                case 'collections':
                    url.unshift('collections');
                case 'database':
                    url.unshift(e('database'));
                case 'databases':
                    url.unshift('databases');
                case 'server':
                    url.unshift(e('server'));
                case 'servers':
                    url.unshift('servers');
                    break;

                default:
                    throw 'Unknown URL type: ' + type;
            }

            return app.baseUrl + url.join('/') + urlQuery;
        },

        update: function() {
            var changed = this.changedAttributes();

            // TODO: fetch servers less often.
            this.servers.url = this.buildUrl('servers');
            this.servers.fetch({reset: true, error: showErrorMessage});

            if (this.has('server') && !_.isEmpty(_.pick(changed, SERVER_PARAMS))) {
                this.currentServer.url = this.buildUrl('server');
                this.currentServer.fetch({
                    reset: true,
                    error: fetchErrorHandler('databases', 'Server Not Found')
                });

                this.databases.url = this.buildUrl('databases');
                this.databases.fetch({reset: true, error: showErrorMessage});
            }

            if (this.has('database') && !_.isEmpty(_.pick(changed, DATABASE_PARAMS))) {
                this.currentDatabase.url = this.buildUrl('database');
                this.currentDatabase.fetch({
                    reset: true,
                    error: fetchErrorHandler('collections', 'Database Not Found')
                });

                this.collections.url = this.buildUrl('collections');
                this.collections.fetch({reset: true, error: showErrorMessage});
            }

            if (this.has('collection') && !_.isEmpty(_.pick(changed, COLLECTION_PARAMS))) {
                this.currentCollection.url = this.buildUrl('collection');
                this.currentCollection.fetch({
                    reset: true,
                    error: fetchErrorHandler('documents', 'Collection Not Found')
                });
            }

            if (this.has('collection') && !_.isEmpty(_.pick(changed, DOCUMENTS_PARAMS))) {
                this.documents.url = this.buildUrl('documents');
                this.documents.fetch({reset: true, error: showErrorMessage});
            }

            if (this.has('document') && !_.isEmpty(_.pick(changed, DOCUMENT_PARAMS))) {
                this.currentDocument.clear({silent: true});
                this.currentDocument.id      = this.get('document');
                this.currentDocument.urlRoot = this.buildUrl('documents');
                this.currentDocument.fetch({
                    reset: true,
                    error: fetchErrorHandler(
                        'document',
                        'Document Not Found',
                        'But I&#146;m sure there are plenty of other nice documents out there&hellip;'
                    )
                });
            }

            if (this.get('explain')) {
                this.explain.url = this.buildUrl('explain');
                this.explain.fetch({error: showErrorMessage});
            }

            function showErrorMessage(model, response) {
                if (response.status !== 404) {
                    try {
                        data = JSON.parse(response.responseText);
                    } catch (e) {
                        data = {};
                    }

                    app.alerts.add({
                        msg:   data.error || 'Unknown error',
                        level: 'danger',
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
