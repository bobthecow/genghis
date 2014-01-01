define(function(require) {
    'use strict';

    var View     = require('genghis/views/view');
    var template = require('hgn!genghis/templates/alert');

    return View.extend({

        tagName:  'div',
        template: template,

        events: {
            'click button.close': 'destroy'
        },

        modelEvents: {
            'change':  'render',
            'destroy': 'remove'
        },

        afterRender: function() {
            this.$('a').addClass('alert-link');
        },

        destroy: function() {
            this.model.destroy();
        }
    });
});
