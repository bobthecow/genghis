Genghis.Views.App = Backbone.View.extend({
    el: 'section#genghis',
    initialize: function() {
        _.bindAll(this, 'showSection');

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
    showSection: function(section) {
        $('body')
            .removeClass('section-servers section-databases section-collections section-documents section-document')
            .addClass('section-'+(_.isArray(section) ? section.join(' section-') : section));

        this.$('section').hide()
            .filter('#'+(_.isArray(section) ? section.join(',#') : section))
                .addClass('spinning')
                .show();

        $(document).scrollTop(0);
    }
});
