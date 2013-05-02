Genghis.Views.ServerRow = Genghis.Views.BaseRow.extend({
    template: Genghis.Templates.ServerRow,

    destroyConfirmText:   function(name) {
        return 'Remove ' + name + ' from the server list?<br><br>This will not affect any data, and you can add it back at any time.';
    },

    destroyConfirmButton: function(name) {
        return '<strong>Yes</strong>, remove '+name+' from server list';
    }
});
