define([
    'underscore', 'genghis/views/view', 'genghis/views', 'genghis/views/alert'
], function(_, View, Views, Alert) {

    return Views.Alerts = View.extend({
        el: 'aside#alerts',

        initialize: function() {
            _.bindAll(this, 'render', 'addModel');

            this.collection.bind('reset', this.render);
            this.collection.bind('add',   this.addModel);
        },

        addModel: function(model) {
            var view = new Alert({model: model});
            this.$el.append(view.render().el);
        }
    });
});
