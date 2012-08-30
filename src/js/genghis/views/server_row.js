Genghis.Views.ServerRow = Genghis.Base.RowView.extend({
    template: Genghis.Templates.ServerRow,
    destroyConfirmButton: function(name) {
        return '<strong>Yes</strong>, remove '+name+' from server list';
    }
});
