define(function(require) {
    'use strict';

    var View     = require('genghis/views/view');
    var Util     = require('genghis/util');
    var template = require('hgn!genghis/templates/explain');

    return View.extend({
        el:       'section#explain',
        template: template,

        ui: {
            '$doc': '.document'
        },

        modelEvents: {
            'sync': 'updateExplain'
        },

        initialize: function() {
            this.render();
        },

        afterRender: function() {
            Util.attachCollapsers(this.$('article')[0]);
        },

        updateExplain: function() {
            this.$doc.html(this.model.prettyPrint());
            this.$el.removeClass('spinning');
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
