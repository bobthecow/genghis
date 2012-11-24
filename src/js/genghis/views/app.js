Genghis.Views.App = Backbone.View.extend({
    el: 'section#genghis',
    initialize: function() {
        _.bindAll(this, 'showMasthead', 'removeMasthead', 'showSection');

        // let's save this for later
        var baseUrl   = this.baseUrl   = this.options.baseUrl;

        // for current selection
        var selection = this.selection = new Genghis.Models.Selection;

        // for messaging
        var alerts    = this.alerts    = new Genghis.Collections.Alerts;

        // initialize all our app views
        this.navView               = new Genghis.Views.Nav({model: selection, baseUrl: baseUrl});
        this.alertsView            = new Genghis.Views.Alerts({collection: alerts});
        this.keyboardShortcutsView = new Genghis.Views.KeyboardShortcuts;
        this.serversView           = new Genghis.Views.Servers({collection: selection.servers});
        this.databasesView         = new Genghis.Views.Databases({
            model:      selection.currentServer,
            collection: selection.databases
        });
        this.collectionsView       = new Genghis.Views.Collections({
            model:      selection.currentDatabase,
            collection: selection.collections
        });
        this.documentsView         = new Genghis.Views.Documents({collection: selection.documents, pagination: selection.pagination});
        this.documentView          = new Genghis.Views.Document({model: selection.currentDocument});


        // initialize the router
        var router = this.router = new Genghis.Router;

        // route to home when the logo is clicked
        $('.navbar a.brand').click(function(e) {
            e.preventDefault();
            router.navigate('', true);
        });

        // check the server status...
        $.getJSON(this.baseUrl + 'check-status')
            .error(alerts.handleError)
            .success(function(status) {
                _.each(status.alerts, function(alert) {
                    alerts.add(_.extend({block: !alert.msg.search(/<(p|ul|ol|div)[ >]/i)}, alert));
                });
            });

        // trigger the first selection change. go go gadget app!
        selection.change();
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
        // remove mastheads when navigating
        this.removeMasthead();

        // show a welcome message the first time they hit the servers page
        if (section == 'servers') {
            this.showWelcome();
        }

        var sectionClass = !!section ? ('section-' + (_.isArray(section) ? section.join(' section-') : section)) : '';

        $('body')
            .removeClass('section-servers section-databases section-collections section-documents section-document')
            .addClass(sectionClass)
            .toggleClass('has-section', !!section);

        this.$('section').hide()
            .filter('#'+(_.isArray(section) ? section.join(',#') : section))
                .addClass('spinning')
                .show();

        $(document).scrollTop(0);
    },
    showWelcome: _.once(function() {
        this.showMasthead('', Genghis.Templates.Welcome.render({version: Genghis.version}), {epic: true, className: 'masthead welcome'});
    })
});
