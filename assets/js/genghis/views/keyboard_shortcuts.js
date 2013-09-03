define([
    'underscore', 'backbone', 'mousetrap', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/keyboard_shortcuts', 'bootstrap.modal'
], function(_, Backbone, Mousetrap, View, Views, template, _1) {

    return Views.KeyboardShortcuts = View.extend({
        tagName:   'div',
        id:        'keyboard-shortcuts',
        className: 'modal',
        template:  template,

        events: {
            'click button.close': 'hide'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'show', 'hide', 'toggle');
            Mousetrap.bind('?', this.toggle);
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
