define(['genghis/views', 'backbone.giraffe'], function(Views, Giraffe) {

    // Let's use a base class!
    return Views.View = Giraffe.View.extend({

        // Really, Hogan, but it looks a lot like JST:
        templateStrategy: 'jst',

        // By default return the model, or the view if no model is set.
        serialize: function() {
            return this.model || this;
        }
    });
});
