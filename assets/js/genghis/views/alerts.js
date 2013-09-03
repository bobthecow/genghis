define([
    'underscore', 'genghis/views/view', 'genghis/views', 'genghis/views/alert', 'backbone.declarative'
], function(_, View, Views, Alert, _1) {

    return Views.Alerts = View.extend({
        el: 'aside#alerts',

        collectionEvents: {
            'reset': 'render',
            'add':   'addModel'
        },

        addModel: function(model) {
            this.attach(new Alert({model: model}));
        }
    });
});
