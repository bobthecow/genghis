define([
  'genghis/views', 'genghis/views/section', 'genghis/views/database_row', 'hgn!genghis/templates/databases'
], function(Views, Section, DatabaseRow, template) {

  return Views.Databases = Section.extend({
      el:       'section#databases',
      template: template,
      rowView:  DatabaseRow,

      formatTitle: function(model) {
          return model.id ? (model.id + ' Databases') : 'Databases';
      }
  });
});
