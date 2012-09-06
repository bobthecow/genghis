Genghis.Views.Documents = Backbone.View.extend({
    el: 'section#documents',
    template: Genghis.Templates.Documents,
    events: {
        'click button.add-document': 'createDocument'
    },
    initialize: function() {
        _.bindAll(
            this, 'render', 'addAll', 'addDocument', 'createDocument',
            'createDocumentIfVisible'
        );

        this.pagination = this.options.pagination;

        this.collection.bind('reset', this.addAll,      this);
        this.collection.bind('add',   this.addDocument, this);

        $(document).bind('keyup', 'c', this.createDocumentIfVisible);

        this.render();
    },
    render: function() {
        $(this.el).html(this.template.render({}));

        this.headerView      = new Genghis.Views.DocumentsHeader({model: this.pagination});
        this.newDocumentView = new Genghis.Views.NewDocument({collection: this.collection});
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
        this.collection.each(this.addDocument);

        $(this.el).removeClass('spinning');
    },
    addDocument: function(document) {
        var view = new Genghis.Views.DocumentView({model: document});
        this.$('.content').append(view.render().el);
    },
    createDocument: function() {
        this.newDocumentView.show();
    },
    createDocumentIfVisible: function(e) {
        if ($(this.el).is(':visible')) {
            e.preventDefault();
            this.createDocument();
        }
    }
});
