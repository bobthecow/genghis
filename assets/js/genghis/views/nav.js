define([
    'jquery', 'underscore', 'backbone-stack', 'genghis/util', 'genghis/views/view', 'genghis/views',
    'genghis/views/nav_section', 'hgn!genghis/templates/nav'
], function($, _, Backbone, Util, View, Views, NavSection, template) {

    return Views.Nav = View.extend({
        tagName:   'ul',
        className: 'nav navbar-nav',
        template:  template,

        events: {
            'click a': 'navigate'
        },

        modelEvents: {
            'change': 'updateSubnav'
        },

        keyboardEvents: {
            's': 'navigateToServers',
            'u': 'navigateUp'
        },

        initialize: function() {
            _.bindAll(
                this, 'render', 'navigate', 'navigateToServers', 'navigateUp', 'updateSubnav'
            );

            this.baseUrl = this.options.baseUrl;

            // TODO: clean this up somehow
            $('body').bind('click', function(e) {
                $('.dropdown-toggle, .menu').parent('li').removeClass('open');
            });

            this.serverNavView = new NavSection({
                className:  'dropdown server',
                model:      this.model.currentServer,
                collection: this.model.servers
            });

            this.databaseNavView = new NavSection({
                className:  'dropdown database',
                model:      this.model.currentDatabase,
                collection: this.model.databases
            });

            this.collectionNavView = new NavSection({
                className:  'dropdown collection',
                model:      this.model.currentCollection,
                collection: this.model.collections
            });
        },

        serialize: function() {
            return {baseUrl: this.baseUrl};
        },

        updateSubnav: function(model) {
            var attrs = model.changedAttributes();

            if (_.has(attrs, 'server')) {
                if (!!attrs.server) {
                    if (!this.serverNavView.isAttached()) {
                        this.attach(this.serverNavView);
                    }
                } else {
                    this.serverNavView.detach(true);
                }
            }

            if (_.has(attrs, 'database')) {
                if (!!attrs.database) {
                    if (!this.databaseNavView.isAttached()) {
                        this.attach(this.databaseNavView);
                    }
                } else {
                    this.databaseNavView.detach(true);
                }
            }

            if (_.has(attrs, 'collection')) {
                if (!!attrs.collection) {
                    if (!this.collectionNavView.isAttached()) {
                        this.attach(this.collectionNavView);
                    }
                } else {
                    this.collectionNavView.detach(true);
                }
            }
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
