define(['genghis/views', 'genghis/views/base_row', 'hgn!genghis/templates/server_row'], function(Views, BaseRow, template) {

  return Views.ServerRow = BaseRow.extend({
      template: template,

      destroyConfirmText:   function(name) {
          return 'Remove ' + name + ' from the server list?<br><br>This will not affect any data, and you can add it back at any time.';
      },

      destroyConfirmButton: function(name) {
          return '<strong>Yes</strong>, remove '+name+' from server list';
      }
  });
});
