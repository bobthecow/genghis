Genghis.Views.Documents = Backbone.View.extend({
    el: 'section#documents',
    template: _.template($('#documents-template').html()),
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
        $(this.el).html(this.template({}));

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
        var view = new Genghis.Views.DocumentView({model: document}).render();
        this.$('.content').append(view.el);
        Genghis.Util.attachCollapsers(view.el, (this.collection.size() > 3));
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