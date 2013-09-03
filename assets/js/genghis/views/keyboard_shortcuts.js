define([
    'underscore', 'backbone', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/keyboard_shortcuts', 'bootstrap.modal', 'backbone.mousetrap'
], function(_, Backbone, View, Views, template, _1, _2) {

    return Views.KeyboardShortcuts = View.extend({
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
