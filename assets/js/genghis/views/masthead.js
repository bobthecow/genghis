define(function(require) {
    'use strict';

    var View     = require('genghis/views/view');
    var template = require('hgn!genghis/templates/masthead');

    return View.extend({
        tagName: 'header',
        attributes: {
            'class': 'masthead'
        },
        template: template,

        initialize: function(options) {
            this.heading = options.heading;
            this.content = options.content || '';
            this.error   = options.error   || false;
            this.epic    = options.epic    || false;
            this.sticky  = options.sticky  || false;

            this.render();
        },

        serialize: function() {
            return {
                heading: this.heading,
                content: this.content
            };
        },

        afterRender: function() {
            this.$el
                .toggleClass('error',  this.error)
                .toggleClass('epic',   this.epic)
                .toggleClass('sticky', this.sticky)
                .insertAfter('header.navbar');
        }
    });
});
