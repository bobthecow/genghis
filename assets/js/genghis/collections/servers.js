define(function(require) {
    'use strict';

    var _       = require('underscore');
    var Giraffe = require('backbone.giraffe');
    var Server  = require('genghis/models/document');

    return Giraffe.Collection.extend({
        model: Server,

        firstChildren: function() {
            return this.collection.reject(function(m) { return m.has('error'); }).slice(0, 10);
        },

        hasMoreChildren: function() {
            return this.collection.length > 10 || this.collection.detect(function(m) { return m.has('error'); });
        }
    });
});
