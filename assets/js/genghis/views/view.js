define(function(require) {
    'use strict';

    var Giraffe = require('backbone.giraffe');

    // Let's use a base class!
    return Giraffe.View.extend({

        // Really, Hogan, but it looks a lot like JST:
        templateStrategy: 'jst',

        // By default return the model, or the view if no model is set.
        serialize: function() {
            return this.model || this;
        }
    });
});
