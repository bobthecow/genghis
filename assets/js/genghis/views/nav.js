define([
    'jquery', 'underscore', 'backbone', 'mousetrap', 'genghis/util', 'genghis/views', 'genghis/views/nav_section',
    'genghis/views/search', 'hgn!genghis/templates/nav'
], function($, _, Backbone, Mousetrap, Util, Views, NavSection, Search, template) {

    return Views.Nav = Backbone.View.extend({
        el:       '.navbar nav',
        template: template,
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
            this.$el.html(this.template({baseUrl: this.baseUrl}));

            this.serverNavView = new NavSection({
                el: this.$('li.server'),
                model: this.model.currentServer,
                collection: this.model.servers
            });

            this.databaseNavView = new NavSection({
                el: this.$('li.database'),
                model: this.model.currentDatabase,
                collection: this.model.databases
            });

            this.collectionNavView = new NavSection({
                el: this.$('li.collection'),
                model: this.model.currentCollection,
                collection: this.model.collections
            });

            this.searchView = new Search({
                model: this.model
            });

            this.$el.append(this.searchView.render().el);

            return this;
        },

        navigate: function(e) {
            if (e.ctrlKey || e.shiftKey || e.metaKey) return;
            e.preventDefault();
            app.router.navigate(Util.route($(e.target).attr('href')), true);
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
});
