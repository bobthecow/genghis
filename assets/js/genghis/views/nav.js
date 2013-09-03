define([
    'jquery', 'underscore', 'backbone', 'genghis/util', 'genghis/views/view', 'genghis/views',
    'genghis/views/nav_section', 'genghis/views/search', 'hgn!genghis/templates/nav', 'backbone.mousetrap'
], function($, _, Backbone, Util, View, Views, NavSection, Search, template, _1) {

    return Views.Nav = View.extend({
        el:       '.navbar nav',
        template: template,

        events: {
            'click a': 'navigate'
        },

        keyboardEvents: {
            's': 'navigateToServers',
            'u': 'navigateUp'
        },

        initialize: function() {
            _.bindAll(
                this, 'render', 'navigate', 'navigateToServers', 'navigateUp'
            );

            this.baseUrl = this.options.baseUrl;

            this.listenTo(this.model, {
                'change': this.updateQuery
            });

            // TODO: clean this up somehow
            $('body').bind('click', function(e) {
                $('.dropdown-toggle, .menu').parent('li').removeClass('open');
            });

            this.render();
        },

        serialize: function() {
            return {baseUrl: this.baseUrl};
        },

        afterRender: function() {
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
