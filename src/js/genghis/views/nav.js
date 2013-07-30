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

        this.baseUrl = this.options.baseUrl;
        this.model.bind('change', this.updateQuery);

        $('body').bind('click', function(e) {
            $('.dropdown-toggle, .menu').parent('li').removeClass('open');
        });

        Mousetrap.bind('s', this.navigateToServers);
        Mousetrap.bind('u', this.navigateUp);

        this.render();
    },
    render: function() {
        this.$el.html(this.template.render({baseUrl: this.baseUrl}));

        this.serverNavView = new Genghis.Views.NavSection({
            el: this.$('li.server'),
            model: this.model.currentServer,
            collection: this.model.servers
        });

        this.databaseNavView = new Genghis.Views.NavSection({
            el: this.$('li.database'),
            model: this.model.currentDatabase,
            collection: this.model.databases
        });

        this.collectionNavView = new Genghis.Views.NavSection({
            el: this.$('li.collection'),
            model: this.model.currentCollection,
            collection: this.model.collections
        });

        this.searchView = new Genghis.Views.Search({
            model: this.model
        });

        this.$el.append(this.searchView.render().el);

        return this;
    },
    navigate: function(e) {
        if (!e.shiftKey && !e.ctrlKey) {
            e.preventDefault();
            app.router.navigate(Genghis.Util.route($(e.target).attr('href')), true);
        }
    },
    navigateToServers: function(e) {
        e.preventDefault();
        app.router.redirectToIndex();
    },
    navigateUp: function(e) {
        e.preventDefault();
        app.router.redirectTo(
            this.model.has('database')   && this.model.get('server'),
            this.model.has('collection') && this.model.get('database'),
            (this.model.has('document') || this.model.has('query')) && this.model.get('collection')
        );
    }
});
