define(function(require) {
    'use strict';

    var Row      = require('genghis/views/row');
    var template = require('hgn!genghis/templates/database_row');

    return Row.extend({
        template:   template,
        isParanoid: true
    });
});
