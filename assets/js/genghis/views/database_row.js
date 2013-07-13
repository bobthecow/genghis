define(['genghis/views', 'genghis/views/base_row', 'hgn!genghis/templates/database_row'], function(Views, BaseRow, template) {

  return Views.DatabaseRow = BaseRow.extend({
      template:   template,
      isParanoid: true
  });

});
