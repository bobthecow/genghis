Genghis.Views.Nav = Backbone.View.extend({
    el: '.topbar nav',
    template: _.template($('#nav-template').html()),
    events: {
        'keypress input#navbar-query': 'findDocuments',
        'click a':                     'navigate'
    },
    initialize: function() {
        _.bindAll(this, 'render', 'toggleSections', 'updateQuery', 'findDocuments', 'navigate');

        this.model.bind('change', this.toggleSections);
        this.model.bind('change', this.updateQuery)

        $('body').bind('click', function(e) {
            $('.dropdown-toggle, .menu').parent('li').removeClass('open');
        });

        this.render();
    },
    render: function() {
        $(this.el).html(this.template({query: this.model.get('query')}));

        this.ServerNavView = new Genghis.Views.NavSection({
            el: $('li.server', this.el),
            model: this.model.CurrentServer,
            collection: this.model.Servers
        })

        this.DatabaseNavView = new Genghis.Views.NavSection({
            el: $('li.database', this.el),
            model: this.model.CurrentDatabase,
            collection: this.model.Databases
        })

        this.CollectionNavView = new Genghis.Views.NavSection({
            el: $('li.collection', this.el),
            model: this.model.CurrentCollection,
            collection: this.model.Collections
        })

        return this;
    },
    toggleSections: function() {
        $(this.ServerNavView.el).toggle(this.model.get('server') != null);
        $(this.DatabaseNavView.el).toggle(this.model.get('database') != null);
        $(this.CollectionNavView.el).toggle(this.model.get('collection') != null);
        this.$('form').toggle(this.model.get('collection') != null);
    },
    updateQuery: function() {
        var q = (this.model.get('query') || this.model.get('document') || '')
                .trim()
                .replace(/^\{\s*\}$/, '')
                .replace(/^\{\s*(['"]?)_id\1\s*:\s*\{\s*(['"]?)\$id\2\s*:\s*(["'])([a-z\d]+)\3\s*\}\s*\}$/, '$4');

        this.$('input#navbar-query').val(q);
    },
    findDocuments: function(e) {
        if (e.keyCode == 13) {
            e.preventDefault();

            var q    = $(e.target).val(),
                base = Genghis.Util.route(this.model.CurrentCollection.url + '/documents'),
                url  = base + (q.match(/^([a-z\d]+)$/i) ? '/' + q : '?' + Genghis.Util.buildQuery({q: encodeURIComponent(q)}));

            App.Router.navigate(url, true);
        }
    },
    navigate: function(e) {
        e.preventDefault();
        App.Router.navigate(Genghis.Util.route($(e.target).attr('href')), true);
    }
});
