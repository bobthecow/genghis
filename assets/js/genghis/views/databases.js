define([
  'genghis/views', 'genghis/views/base_section', 'genghis/views/database_row', 'hgn!genghis/templates/databases'
], function(Views, BaseSection, DatabaseRow, template) {

  return Views.Databases = BaseSection.extend({
      el:       'section#databases',
      template: template,
      rowView:  DatabaseRow,

      formatTitle: function(model) {
          return model.id ? (model.id + ' Databases') : 'Databases';
      }
  });
});
