define(function(require) {
    'use strict';

    var _       = require('underscore');
    var Giraffe = require('backbone.giraffe');

    return Giraffe.Model.extend({

        defaults: {
            page:  1,
            pages: 1,
            limit: 50,
            count: 0,
            total: 0
        },

        initialize: function() {
            _.bindAll(this, 'decrementTotal');
        },

        decrementTotal: function() {
            this.set({
                total: this.get('total') - 1,
                count: this.get('count') - 1
            });
        }
    });
});
