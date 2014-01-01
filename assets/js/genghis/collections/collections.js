define(function(require) {
    'use strict';

    var BaseCollection = require('genghis/collections/base_collection');
    var Collection     = require('genghis/models/collection');

    return BaseCollection.extend({
        model: Collection
    });
});
