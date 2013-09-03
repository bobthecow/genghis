define([
    'jquery', 'underscore', 'backbone', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/nav_section',
    'hgn!genghis/templates/nav_section_menu', 'jquery.hoverintent', 'backbone.declarative'
], function($, _, Backbone, View, Views, template, menuTemplate, _1, _2) {

    return Views.NavSection = View.extend({
        template:     template,
        menuTemplate: menuTemplate,

        ui: {
            '$toggle': '.dropdown-toggle',
            '$menu':   'ul.dropdown-menu'
        },

        modelEvents: {
            'change': 'updateLink'
        },

        collectionEvents: {
            'reset': 'renderMenu'
        },

        initialize: function() {
            this.render();
        },

        afterRender: function() {
            this.$toggle.hoverIntent(function(e) {
                $(e.target)
                    .parent('li').addClass('open')
                    .siblings('li').removeClass('open');
            }, $.noop);
        },

        updateLink: function() {
            this.$toggle.text(this.model.id ? this.model.id : '').attr('href', this.model.id ? this.model.url : '');
        },

        renderMenu: function() {
            this.$menu.html(this.menuTemplate({model: this.model, collection: this.collection}));

            // Handle really wide badges on the menu dropdown
            this.$menu.find('a span').each(function(i, el) {
                var $el = $(el);
                var len = $el.text().length;
                if (len > 3) {
                    $el.parent().css('padding-right', '' + (len + 0.5) + 'em');
                }
            });
        }
    });
});
