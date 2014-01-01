define(function(require) {
    'use strict';

    var _         = require('underscore');
    var BaseModel = require('genghis/models/base_model');

    return BaseModel.extend({

      editable: function() {
          return !!this.get('editable');
      },

      firstChildren: function() {
          return _.first((this.get('databases') || []), 15);
      },

      error: function() {
          return this.get('error');
      }
  });
});
