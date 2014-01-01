define(function(require) {
    'use strict';

    var Backbone = require('backbone');

    require('backbone.declarative');
    require('backbone.mousetrap');

    // This is ugly, but it'll do for now. Mix in all the Backbone stuff without
    // having to declare 'em all as individual requirements.
    return Backbone;
});
