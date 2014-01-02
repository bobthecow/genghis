define(function(require) {
    'use strict';

    var $                     = require('jquery');
    var _                     = require('underscore');
    var Giraffe               = require('backbone.giraffe');
    var Selection             = require('genghis/models/selection');
    var Alerts                = require('genghis/collections/alerts');
    var Router                = require('genghis/router');
    var TitleView             = require('genghis/views/title');
    var NavbarView            = require('genghis/views/navbar');
    var AlertsView            = require('genghis/views/alerts');
    var KeyboardShortcutsView = require('genghis/views/keyboard_shortcuts');
    var ServersView           = require('genghis/views/servers');
    var DatabasesView         = require('genghis/views/databases');
    var CollectionsView       = require('genghis/views/collections');
    var DocumentsView         = require('genghis/views/documents');
    var ExplainView           = require('genghis/views/explain');
    var DocumentSectionView   = require('genghis/views/document_section');
    var MastheadView          = require('genghis/views/masthead');
    var welcomeTemplate       = require('hgn!genghis/templates/welcome');

    return Giraffe.App.extend({
        el: 'section#genghis',

        initialize: function(options) {
            _.bindAll(this, 'showMasthead', 'removeMasthead', 'showSection');

            // let's save this for later
            var baseUrl = this.baseUrl = options.baseUrl;

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
