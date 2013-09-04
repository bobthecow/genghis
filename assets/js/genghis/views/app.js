define([
    'jquery', 'underscore', 'backbone.giraffe', 'genghis/views', 'genghis/models/selection',
    'genghis/collections/alerts', 'genghis/router', 'genghis/views/title', 'genghis/views/navbar',
    'genghis/views/alerts', 'genghis/views/keyboard_shortcuts', 'genghis/views/servers',
    'genghis/views/databases', 'genghis/views/collections', 'genghis/views/documents',
    'genghis/views/explain', 'genghis/views/document_section', 'genghis/views/masthead',
    'hgn!genghis/templates/welcome'
], function(
    $, _, Giraffe, Views, Selection, Alerts, Router, TitleView, NavbarView, AlertsView,
    KeyboardShortcutsView, ServersView, DatabasesView, CollectionsView, DocumentsView,
    ExplainView, DocumentSectionView, MastheadView, welcomeTemplate
) {

    return Views.App = Giraffe.App.extend({
        el: 'section#genghis',

        initialize: function() {
            _.bindAll(this, 'showMasthead', 'removeMasthead', 'showSection');

            // let's save this for later
            var baseUrl = this.baseUrl = this.options.baseUrl;

            // for current selection
            var selection = this.selection = new Selection();

            // for messaging
            var alerts = this.alerts = new Alerts();

            // initialize the router
            var router = this.router = new Router({app: this});
            this.listenTo(this.router, 'all', this.autoShowSection);

            // initialize all our app views
            this.titleView             = new TitleView({model: router});
            this.navbarView            = new NavbarView({model: selection, baseUrl: this.baseUrl, router: router});
            this.alertsView            = new AlertsView({collection: alerts});
            this.keyboardShortcutsView = new KeyboardShortcutsView();
            this.serversView           = new ServersView({collection: selection.servers});
            this.databasesView         = new DatabasesView({
                model:      selection.currentServer,
                collection: selection.databases
            });
            this.collectionsView       = new CollectionsView({
                model:      selection.currentDatabase,
                collection: selection.collections
            });
            this.documentsView         = new DocumentsView({
                model:      selection.currentCollection,
                collection: selection.documents,
                pagination: selection.pagination
            });
            this.explainView           = new ExplainView({model: selection.explain});
            this.documentSectionView   = new DocumentSectionView({model: selection.currentDocument});

            // Let's just keep these for later...
            this.sections = {
                'servers':     this.serversView,
                'databases':   this.databasesView,
                'collections': this.collectionsView,
                'documents':   this.documentsView,
                'explain':     this.explainView,
                'document':    this.documentSectionView
            };

            // check the server status...
            $.getJSON(this.baseUrl + 'check-status')
                .error(alerts.handleError)
                .success(function(status) {
                    _.each(status.alerts, function(alert) {
                        alerts.add(_.extend({block: !alert.msg.search(/<(p|ul|ol|div)[ >]/i)}, alert));
                    });
                });

            // trigger the first selection change. go go gadget app!
            _.defer(this.selection.update);
        },

        showMasthead: function(heading, content, opt) {
            // remove any old mastheads
            this.removeMasthead(true);
            new MastheadView(_.extend(opt || {}, {
                heading: heading,
                content: content || ''
            }));
        },

        removeMasthead: function(force) {
            var masthead = $('header.masthead');
            if (!force) {
                masthead = masthead.not('.sticky');
            }
            masthead.remove();
        },

        autoShowSection: function(route) {
            var section;

            switch (route) {
                case 'route:index':
                    section = 'servers';
                    break;

                case 'route:server':
                    section = 'databases';
                    break;

                case 'route:database':
                    section = 'collections';
                    break;

                case 'route:collection':
                case 'route:collectionQuery':
                    section = 'documents';
                    break;

                case 'route:explainQuery':
                    section = 'explain';
                    break;

                case 'route:document':
                    section = 'document';
                    break;

                default:
                    return;
            }

            this.showSection(section);
        },

        showSection: function(section) {
            var hasSection = section && _.has(this.sections, section);

            // remove mastheads when navigating
            this.removeMasthead();

            // show a welcome message the first time they hit the servers page
            if (section == 'servers') {
                this.showWelcome();
            }

            // TODO: move this somewhere else?
            $('body').toggleClass('has-section', hasSection);

            _.each(this.sections, function(view, name) {
                if (name != section) {
                    view.hide();
                }
            });

            if (hasSection) {
                this.sections[section].show();
            }
        },

        showWelcome: _.once(function() {
            this.showMasthead('', welcomeTemplate({version: Genghis.version}), {epic: true, className: 'masthead welcome'});
        })
    });

});
