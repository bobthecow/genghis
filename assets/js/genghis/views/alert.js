define([
    'underscore', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/alert'
], function(_, View, Views, template) {

    return Views.Alert = View.extend({

        tagName:  'div',
        template: template,

        events: {
            'click button.close': 'destroy'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'remove', 'destroy');

            this.model.bind('change',  this.render);
            this.model.bind('destroy', this.remove);
        },

        afterRender: function() {
            this.$('a').addClass('alert-link');
        },

        destroy: function() {
            this.model.destroy();
        }
    });
});
