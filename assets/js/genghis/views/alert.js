define([
    'underscore', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/alert'
], function(_, View, Views, template) {

    return Views.Alert = View.extend({

        tagName:  'div',
        template: template,

        events: {
            'click a.close': 'destroy'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'remove', 'destroy');

            this.model.bind('change',  this.render);
            this.model.bind('destroy', this.remove);
        },

        render: function() {
            this.$el.html(this.template(this.model));
            this.$('a').addClass('alert-link');

            return this;
        },

        destroy: function() {
            this.model.destroy();
        },

        remove: function() {
            this.$el.remove();
        }
    });
});
