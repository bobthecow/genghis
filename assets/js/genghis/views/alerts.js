define([
    'underscore', 'genghis/views/view', 'genghis/views', 'genghis/views/alert'
], function(_, View, Views, Alert) {

    return Views.Alerts = View.extend({
        el: 'aside#alerts',

        initialize: function() {
            this.listenTo(this.collection, {
                'reset': this.render,
                'add':   this.addModel
            });
        },

        addModel: function(model) {
            this.attach(new Alert({model: model}));
        }
    });
});
