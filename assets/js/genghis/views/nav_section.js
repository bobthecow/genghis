define(function(require) {
    'use strict';

    var $            = require('jquery');
    var View         = require('genghis/views/view');
    var template     = require('hgn!genghis/templates/nav_section');
    var menuTemplate = require('hgn!genghis/templates/nav_section_menu');

    require('jquery.hoverintent');

    return View.extend({
        tagName:      'li',
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
            'add':    'renderMenu',
            'remove': 'renderMenu',
            'reset':  'renderMenu'
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
