Genghis.Views.Nav = Backbone.View.extend({
    el: '.navbar nav',
    template: Genghis.Templates.Nav,
    events: {
        'click a': 'navigate'
    },
    initialize: function() {
        _.bindAll(
            this, 'render', 'navigate', 'navigateToServers', 'navigateUp'
        );

        this.model.bind('change', this.updateQuery);

        $('body').bind('click', function(e) {
            $('.dropdown-toggle, .menu').parent('li').removeClass('open');
        });

        $(document).bind('keyup', 's', this.navigateToServers);
        $(document).bind('keyup', 'u', this.navigateUp);

        this.render();
    },
    render: function() {
        $(this.el).html(this.template.render({baseUrl: Genghis.baseUrl}));

        this.ServerNavView = new Genghis.Views.NavSection({
            el: $('li.server', this.el),
            model: this.model.CurrentServer,
            collection: this.model.Servers
        });

        this.DatabaseNavView = new Genghis.Views.NavSection({
            el: $('li.database', this.el),
            model: this.model.CurrentDatabase,
            collection: this.model.Databases
        });

        this.CollectionNavView = new Genghis.Views.NavSection({
            el: $('li.collection', this.el),
            model: this.model.CurrentCollection,
            collection: this.model.Collections
        });

        this.SearchView = new Genghis.Views.Search({
            model: this.model
        });

        $(this.el).append(this.SearchView.render().el);

        return this;
    },
    navigate: function(e) {
        e.preventDefault();
        App.Router.navigate(Genghis.Util.route($(e.target).attr('href')), true);
    },
    navigateToServers: function(e) {
        e.preventDefault();
        App.Router.redirectToIndex();
    },
    navigateUp: function(e) {
        e.preventDefault();
        App.Router.redirectTo(
            this.model.has('database')   && this.model.get('server'),
            this.model.has('collection') && this.model.get('database'),
            (this.model.has('document') || this.model.has('query')) && this.model.get('collection')
        );
    }
});
