define(function(require) {
    'use strict';

    var Giraffe = require('backbone.giraffe');

    return Giraffe.Collection.extend({
        firstChildren: function() {
            return this.collection.toArray().slice(0, 10);
        },
        hasMoreChildren: function() {
            return this.collection.length > 10;
        }
    });
});
