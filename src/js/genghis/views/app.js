Genghis.Views.App = Backbone.View.extend({
    el: 'section#genghis',
    initialize: function() {
        _.bindAll(this, 'showMasthead', 'removeMasthead', 'showSection');

        // let's save this for later
        var baseUrl   = this.baseUrl   = this.options.baseUrl;

        // for current selection
        var selection = this.selection = new Genghis.Models.Selection();

        // for messaging
        var alerts    = this.alerts    = new Genghis.Collections.Alerts();

        // initialize the router
        var router = this.router = new Genghis.Router();

        // initialize all our app views
        this.navbarView            = new Genghis.Views.Navbar({model: selection, baseUrl: baseUrl, router: router});
        this.alertsView            = new Genghis.Views.Alerts({collection: alerts});
        this.keyboardShortcutsView = new Genghis.Views.KeyboardShortcuts();
        this.serversView           = new Genghis.Views.Servers({collection: selection.servers});
        this.databasesView         = new Genghis.Views.Databases({
            model:      selection.currentServer,
            collection: selection.databases
        });
        this.collectionsView       = new Genghis.Views.Collections({
            model:      selection.currentDatabase,
            collection: selection.collections
        });
        this.documentsView         = new Genghis.Views.Documents({
            model:      selection.currentCollection,
            collection: selection.documents,
            pagination: selection.pagination
        });
        this.explainView           = new Genghis.Views.Explain({model: selection.explain});
        this.documentView          = new Genghis.Views.Document({model: selection.currentDocument});

        // Let's just keep these for later...
        this.sections = {
            'servers':     this.serversView,
            'databases':   this.databasesView,
            'collections': this.collectionsView,
            'documents':   this.documentsView,
            'explain':     this.explainView,
            'document':    this.documentView
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
        _.defer(function() {
            selection.trigger('change');
        });
    },
    showMasthead: function(heading, content, opt) {
        // remove any old mastheads
        this.removeMasthead(true);
        mastheadView = new Genghis.Views.Masthead(_.extend(opt || {}, {
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
        this.showMasthead('', Genghis.Templates.Welcome.render({version: Genghis.version}), {epic: true, className: 'masthead welcome'});
    })
});
