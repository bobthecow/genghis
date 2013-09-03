define([
    'underscore', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/alert'
], function(_, View, Views, template) {

    return Views.Alert = View.extend({

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
