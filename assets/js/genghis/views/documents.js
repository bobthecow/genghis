define(function(require) {
    'use strict';

    var $               = require('jquery');
    var _               = require('underscore');
    var Modernizr       = require('modernizr-detects');
    var View            = require('genghis/views/view');
    var DocumentsHeader = require('genghis/views/documents_header');
    var Pagination      = require('genghis/views/pagination');
    var DocumentView    = require('genghis/views/document');
    var NewDocument     = require('genghis/views/new_document');
    var NewGridFile     = require('genghis/views/new_grid_file');
    var template        = require('hgn!genghis/templates/documents');

    return View.extend({
        el:       'section#documents',
        template: template,

        ui: {
            '$content':   '.content',
            '$addButton': 'button.add-document'
        },

        events: {
            'click     $addButton':         'createDocument',

            // This class is toggled to change the button between "create document"
            // and "file upload", so we're totally not adding it to the UI hash above.
            'dragover  button.file-upload': 'dragGridFile',
            'dragleave button.file-upload': 'dragLeave',
            'drop      button.file-upload': 'dropGridFile'
        },

        keyboardEvents: {
            'c': 'createDocument'
        },

        collectionEvents: {
            'reset':   'addAll',
            'add':     'addDocument',
            'request': 'onRequest',
            'sync':    'onSync'
        },

        initialize: function(options) {
            _.bindAll(
                this, 'render', 'addAll', 'addDocument', 'createDocument', 'dragGridFile', 'dragLeave', 'dropGridFile',
                'onRequest', 'onSync'
            );

            this.pagination = options.pagination;
            this.render();
        },

        afterRender: function() {
            this.headerView = new DocumentsHeader({
                el:    this.$('header'),
                model: this.pagination
            });

            this.paginationView = new Pagination({
                el:         this.$('.pagination-wrapper'),
                model:      this.pagination,
                collection: this.collection
            });

            this.addAll();
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
            this.bindKeyboardEvents();
            $('body').addClass('section-' + this.$el.attr('id'));
            this.$el.show();
            $(document).scrollTop(0);
        },

        hide: function() {
            this.unbindKeyboardEvents();
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
