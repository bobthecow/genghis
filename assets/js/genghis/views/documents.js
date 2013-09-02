define([
    'jquery', 'underscore', 'backbone', 'mousetrap', 'modernizr-detects', 'genghis/views/view',
    'genghis/views', 'genghis/views/documents_header', 'genghis/views/pagination', 'genghis/views/document',
    'genghis/views/new_document', 'genghis/views/new_grid_file', 'hgn!genghis/templates/documents'
], function($, _, Backbone, Mousetrap, Modernizr, View, Views, DocumentsHeader, Pagination, DocumentView, NewDocument, NewGridFile, template) {

    return Views.Documents = View.extend({
        el:       'section#documents',
        template: template,

        events: {
            'click     button.add-document': 'createDocument',
            'dragover  button.file-upload':  'dragGridFile',
            'dragleave button.file-upload':  'dragLeave',
            'drop      button.file-upload':  'dropGridFile'
        },

        initialize: function() {
            _.bindAll(
                this, 'render', 'addAll', 'addDocument', 'createDocument', 'dragGridFile', 'dragLeave', 'dropGridFile',
                'onRequest', 'onSync'
            );

            this.pagination = this.options.pagination;

            this.collection.bind('reset',   this.addAll);
            this.collection.bind('add',     this.addDocument);
            this.collection.bind('request', this.onRequest);
            this.collection.bind('sync',    this.onSync);

            this.render();
        },

        render: function() {
            this.$el.html(this.template({}));

            this.headerView      = new DocumentsHeader({model: this.pagination});
            this.paginationView  = new Pagination({
                el: this.$('.pagination-wrapper'),
                model: this.pagination,
                collection: this.collection
            });

            // TODO: remove this after wiring up UI hash
            this.$content   = this.$('.content');
            this.$addButton = this.$('button.add-document');

            this.addAll();

            return this;
        },

        addAll: function() {
            this.$content.html('');
            this.$addButton
                .text(this.model.isGridCollection() ? 'Upload file' : 'Add document')
                .toggleClass('file-upload', this.model.isGridCollection());
            this.collection.each(this.addDocument);
        },

        addDocument: function(document) {
            var view = new DocumentView({model: document});
            this.$content.append(view.render().el);
        },

        createDocument: function(e) {
            if (e && e.preventDefault) {
                e.preventDefault();
            }

            if (this.model.isGridCollection()) {
                // yeah, it's not worth our time
                if (!Modernizr.filereader) {
                    app.alerts.create({
                        msg:   '<h2>Unable to upload file.</h2> Your browser does not support the File API. Please use a modern browser.',
                        level: 'danger',
                        block: true
                    });

                    return;
                }

                this.getNewGridFileView().show();
            } else {
                this.getNewDocumentView().show();
            }
        },

        dragGridFile: function(e) {
            e.stopPropagation();
            e.preventDefault();
            e.originalEvent.dataTransfer.dropEffect = 'copy';
            $(e.target).addClass('active');
        },

        dragLeave: function(e) {
            $(e.target).removeClass('active');
        },

        dropGridFile: function(e) {
            e.stopPropagation();
            e.preventDefault();

            $(e.target).removeClass('active');

            // yeah, it's not worth our time
            if (!Modernizr.filereader) {
                app.alerts.create({
                    msg:   '<h2>Unable to upload file.</h2> Your browser does not support the File API. Please use a modern browser.',
                    level: 'danger',
                    block: true
                });

                return;
            }

            this.getNewGridFileView()
                .showMetadata(e.originalEvent.dataTransfer.files[0]);
        },

        getNewDocumentView: function() {
            if (!this.newDocumentView) {
                this.newDocumentView = new NewDocument({collection: this.collection});
            }

            return this.newDocumentView;
        },

        getNewGridFileView: function() {
            if (!this.newGridFileView) {
                this.newGridFileView = new NewGridFile({collection: this.collection});
            }

            return this.newGridFileView;
        },

        show: function() {
            Mousetrap.bind('c', this.createDocument);
            $('body').addClass('section-' + this.$el.attr('id'));
            this.$el.show();
            $(document).scrollTop(0);
        },

        hide: function() {
            Mousetrap.unbind('c');
            $('body').removeClass('section-' + this.$el.attr('id'));
            this.$el.hide();
        },

        onRequest: function() {
            this.$el.addClass('spinning');
        },

        onSync: function() {
            this.$el.removeClass('spinning');
        }
    });
});
