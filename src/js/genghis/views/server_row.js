Genghis.Views.ServerRow = Genghis.Views.BaseRow.extend({
    template: Genghis.Templates.ServerRow,
    destroyConfirmButton: function(name) {
        return '<strong>Yes</strong>, remove '+name+' from server list';
    }
});
