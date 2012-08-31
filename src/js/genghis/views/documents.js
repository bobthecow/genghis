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

        this.collection.bind('reset', this.addAll,      this);
        this.collection.bind('add',   this.addDocument, this);

        $(document).bind('keyup', 'c', this.createDocumentIfVisible);

        this.render();
    },
    render: function() {
        $(this.el).html(this.template.render({readOnly: Genghis.features.readOnly}));

        this.HeaderView      = new Genghis.Views.DocumentsHeader({model: Genghis.Selection.Pagination});
        this.NewDocumentView = new Genghis.Views.NewDocument({collection: Genghis.Selection.Documents});
        this.PaginationView  = new Genghis.Views.Pagination({
            el: this.$('.pagination-wrapper'),
            model: Genghis.Selection.Pagination,
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
        this.NewDocumentView.show();
    },
    createDocumentIfVisible: function(e) {
        if ($(this.el).is(':visible')) {
            e.preventDefault();
            this.createDocument();
        }
    }
});
