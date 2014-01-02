define(function(require) {
    'use strict';

    var View     = require('genghis/views/view');
    var Nav      = require('genghis/views/nav');
    var Search   = require('genghis/views/search');
    var template = require('hgn!genghis/templates/navbar');

    return View.extend({
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

        initialize: function(options) {
            this.router  = options.router;
            this.baseUrl = options.baseUrl;

            this.navView = new Nav({
                model:   this.model,
                baseUrl: this.baseUrl
            });

            this.searchView = new Search({
                model: this.model
            });

            this.render();
        },

        serialize: function() {
            return {baseUrl: this.baseUrl};
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
