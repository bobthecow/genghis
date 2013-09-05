define([
    'backbone-stack', 'genghis/views/view', 'genghis/views', 'genghis/views/nav', 'genghis/views/search', 'hgn!genghis/templates/navbar'
], function(Backbone, View, Views, Nav, Search, template) {

    return Views.Navbar = View.extend({
        el:       '.navbar',
        template: template,

        ui: {
            '$nav': 'nav'
        },

        events: {
            'click a.navbar-brand': 'onClickBrand'
        },

        modelEvents: {
            'change:collection': 'onChangeCollection'
        },

        initialize: function() {
            this.router = this.options.router;

            this.navView = new Nav({
                model:   this.model,
                baseUrl: this.options.baseUrl
            });

            this.searchView = new Search({
                model: this.model
            });

            this.render();
        },

        serialize: function() {
            return {baseUrl: this.options.baseUrl};
        },

        afterRender: function() {
            this.navView.attachTo(this.$nav);
        },

        onChangeCollection: function(model) {
            if (model.get('collection')) {
                if (!this.searchView.isAttached()) {
                    this.searchView.attachTo(this.$nav);
                }
            } else {
                if (this.searchView.isAttached()) {
                    this.searchView.detach(true);
                }
            }
        },

        onClickBrand: function(e) {
            if (e.ctrlKey || e.shiftKey || e.metaKey) return;
            e.preventDefault();
            this.router.navigate('', true);
        }
    });
});
