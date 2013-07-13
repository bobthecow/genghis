define(['backbone', 'genghis/views', 'genghis/views/nav'], function(Backbone, Views, Nav) {

    return Views.Navbar = Backbone.View.extend({
        el: '.navbar',
        events: {
            'click a.brand': 'onClickBrand'
        },

        initialize: function() {
            this.router  = this.options.router;
            this.navView = new Nav({model: this.model, baseUrl: this.options.baseUrl});
        },

        onClickBrand: function(e) {
            if (e.ctrlKey || e.shiftKey || e.metaKey) return;
            e.preventDefault();
            this.router.navigate('', true);
        }
    });
});
