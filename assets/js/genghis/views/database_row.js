define(['genghis/views', 'genghis/views/row', 'hgn!genghis/templates/database_row'], function(Views, Row, template) {

  return Views.DatabaseRow = Row.extend({
      template:   template,
      isParanoid: true
  });

});
