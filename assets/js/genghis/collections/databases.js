define(function(require) {
    'use strict';

    var BaseCollection = require('genghis/collections/base_collection');
    var Database       = require('genghis/models/database');

    return BaseCollection.extend({
        model: Database
    });
});
