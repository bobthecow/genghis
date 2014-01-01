define(function(require) {
    'use strict';

    var Section     = require('genghis/views/section');
    var DatabaseRow = require('genghis/views/database_row');
    var template    = require('hgn!genghis/templates/databases');

    return Section.extend({
        el:       'section#databases',
        template: template,
        rowView:  DatabaseRow,

        formatTitle: function(model) {
            return model.id ? (model.id + ' Databases') : 'Databases';
        }
    });
});
