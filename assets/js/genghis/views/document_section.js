define(function(require) {
    'use strict';

    var $            = require('jquery');
    var _            = require('underscore');
    var View         = require('genghis/views/view');
    var DocumentView = require('genghis/views/document');
    var template     = require('hgn!genghis/templates/document_section');

    return View.extend({
        el:       'section#document',
        template: template,

        ui: {
            '$content': '.content'
        },

        modelEvents: {
            'change': 'render'
        },

        afterRender: function() {
            this.$el.removeClass('spinning');
            var view = new DocumentView({model: this.model});
            this.$content.html(view.render().el);
        },

        show: function() {
            $('body').addClass('section-' + this.$el.attr('id'));
            this.$el.addClass('spinning').show();
            $(document).scrollTop(0);
        },

        hide: function() {
            $('body').removeClass('section-' + this.$el.attr('id'));
            this.$el.hide();
        }
    });
});
