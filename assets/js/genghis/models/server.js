define(['underscore', 'genghis/models', 'genghis/models/base_model'], function(_, Models, BaseModel) {

    return Models.Server = BaseModel.extend({

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
