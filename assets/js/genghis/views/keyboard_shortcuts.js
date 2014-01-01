define(function(require) {
    'use strict';

    var _        = require('underscore');
    var View     = require('genghis/views/view');
    var template = require('hgn!genghis/templates/keyboard_shortcuts');

    require('bootstrap.modal');
    require('backbone.mousetrap');

    return View.extend({
        tagName:   'div',
        id:        'keyboard-shortcuts',
        className: 'modal',
        template:  template,

        events: {
            'click button.close': 'hide'
        },

        keyboardEvents: {
            '?': 'toggle'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'show', 'hide', 'toggle');
            this.render();
        },

        afterRender: function() {
            $('footer a.keyboard-shortcuts')
                .click(this.show)
                .show();

            this.$el.modal({
                backdrop: true,
                keyboard: true,
                show:     false
            });
        },

        show: function(e) {
            e.preventDefault();
            this.$el.modal('show');
        },

        hide: function(e) {
            e.preventDefault();
            this.$el.modal('hide');
        },

        toggle: function() {
            this.$el.modal('toggle');
        }
    });
});
