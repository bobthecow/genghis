Genghis.Views.App = Backbone.View.extend({
    el: 'section#genghis',
    initialize: function() {
        _.bindAll(this, 'showSection');

        // let's save this for later
        Genghis.baseUrl = this.options.base_url;

        // for current selection
        Genghis.Selection    = new Genghis.Models.Selection();

        // for messaging
        Genghis.Alerts       = new Genghis.Collections.Alerts();

        // initialize all our app views
        this.NavView               = new Genghis.Views.Nav({model: Genghis.Selection});
        this.AlertsView            = new Genghis.Views.Alerts({collection: Genghis.Alerts});
        this.KeyboardShortcutsView = new Genghis.Views.KeyboardShortcuts();
        this.ServersView           = new Genghis.Views.Servers({collection: Genghis.Selection.Servers});
        this.DatabasesView         = new Genghis.Views.Databases({
            model: Genghis.Selection.CurrentServer,
            collection: Genghis.Selection.Databases
        });
        this.CollectionsView       = new Genghis.Views.Collections({
            model: Genghis.Selection.CurrentDatabase,
            collection: Genghis.Selection.Collections
        });
        this.DocumentsView         = new Genghis.Views.Documents({collection: Genghis.Selection.Documents});
        this.DocumentView          = new Genghis.Views.Document({model: Genghis.Selection.CurrentDocument});


        // initialize the router
        this.Router = new Genghis.Router();

        // route to home when the logo is clicked
        $('.navbar a.brand').click(function(e) {
            e.preventDefault();
            App.Router.navigate('', true);
        });

        // check the server status...
        $.getJSON(Genghis.baseUrl + 'check-status')
            .error(Genghis.Alerts.handleError)
            .success(function(status) {
                _.each(status.alerts, function(alert) {
                    Genghis.Alerts.add(_.extend({block: !alert.msg.search(/<(p|ul|ol|div)[ >]/i)}, alert));
                });
            });

        // trigger the first selection change. go go gadget app!
        Genghis.Selection.change();
    },
    showSection: function(section) {
        this.$('section').hide()
            .filter('#'+(_.isArray(section) ? section.join(',#') : section))
                //.addClass('spinning')
                .show();

        $(document).scrollTop(0);
    }
});
