define([
    'jquery', 'underscore', 'backbone', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/nav_section',
    'hgn!genghis/templates/nav_section_menu', 'jquery.hoverintent'
], function($, _, Backbone, View, Views, template, menuTemplate, _1) {

    return Views.NavSection = View.extend({
        template:     template,
        menuTemplate: menuTemplate,

        initialize: function() {
            _.bindAll(this, 'render');

            this.model.bind('change',     this.updateLink, this);
            this.collection.bind('reset', this.renderMenu, this);

            this.render();
        },

        render: function() {
            this.$el.html(this.template(this.model));

            this.$('.dropdown-toggle').hoverIntent(function(e) {
                $(e.target)
                    .parent('li').addClass('open')
                        .siblings('li').removeClass('open');
            }, $.noop);

            return this;
        },

        updateLink: function() {
            this.$('a.dropdown-toggle').text(this.model.id ? this.model.id : '').attr('href', this.model.id ? this.model.url : '');
        },

        renderMenu: function() {
            this.$('ul.dropdown-menu').html(this.menuTemplate({model: this.model, collection: this.collection}));

            // Handle really wide badges on the menu dropdown
            this.$('ul.dropdown-menu a span').each(function(i, el) {
                var $el = $(el);
                var len = $el.text().length;
                if (len > 3) {
                    $el.parent().css('padding-right', '' + (len + 0.5) + 'em');
                }
            });
        }
    });
});
