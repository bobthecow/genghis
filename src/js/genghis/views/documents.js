Genghis.Views.Documents = Backbone.View.extend({
    el: 'section#documents',
    template: Genghis.Templates.Documents,
    events: {
        'click button.add-document': 'createDocument'
    },
    initialize: function() {
        _.bindAll(this, 'render', 'addAll', 'addDocument', 'createDocument', 'createDocumentIfVisible');

        this.pagination = this.options.pagination;

        this.collection.bind('reset', this.addAll,      this);
        this.collection.bind('add',   this.addDocument, this);

        $(document).bind('keyup', 'c', this.createDocumentIfVisible);

        this.render();
    },
    render: function() {
        $(this.el).html(this.template.render({}));

        this.headerView      = new Genghis.Views.DocumentsHeader({model: this.pagination});
        this.paginationView  = new Genghis.Views.Pagination({
            el: this.$('.pagination-wrapper'),
            model: this.pagination,
            collection: this.collection
        });

        this.addAll();

        return this;
    },
    addAll: function() {
        this.$('.content').html('');
        this.$('button.add-document')
            .text(this.model.isGridCollection() ? 'Upload file' : 'Add document')
            .toggleClass('file-upload', this.model.isGridCollection());
        this.collection.each(this.addDocument);

        $(this.el).removeClass('spinning');
    },
    addDocument: function(document) {
        var view = new Genghis.Views.DocumentView({model: document});
        this.$('.content').append(view.render().el);
    },
    createDocument: function() {
        if (this.model.isGridCollection()) {
            // yeah, it's not worth our time
            if (!Modernizr.filereader) {
                app.alerts.create({
                    msg:   '<h2>Unable to upload file.</h2> Your browser does not support the File API. Please use a modern browser.',
                    level: 'error',
                    block: true
                });

                return;
            }

            this.getNewGridFileView().show();
        } else {
            this.getNewDocumentView().show();
        }
    },
    getNewDocumentView: function() {
        if (!this.newDocumentView) {
            this.newDocumentView = new Genghis.Views.NewDocument({collection: this.collection});
        }

        return this.newDocumentView;
    },
    getNewGridFileView: function() {
        if (!this.newGridFileView) {
            this.newGridFileView = new Genghis.Views.NewGridFile({collection: this.collection});
        }

        return this.newGridFileView;
    },
    createDocumentIfVisible: function(e) {
        if ($(this.el).is(':visible')) {
            e.preventDefault();
            this.createDocument();
        }
    }
});
