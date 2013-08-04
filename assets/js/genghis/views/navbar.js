define(['backbone', 'genghis/views/view', 'genghis/views', 'genghis/views/nav'], function(Backbone, View, Views, Nav) {

    return Views.Navbar = View.extend({
        el: '.navbar',
        events: {
            'click a.navbar-brand': 'onClickBrand'
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
