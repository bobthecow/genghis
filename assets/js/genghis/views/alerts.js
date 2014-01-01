define(function(require) {
    'use strict';

    var View  = require('genghis/views/view');
    var Alert = require('genghis/views/alert');

    return View.extend({
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
