Genghis.Views.DatabaseRow = Genghis.Base.RowView.extend({
    template: Genghis.Templates.DatabaseRow,
    destroy: function() {
        var model = this.model;
        var name  = model.get('name');

        apprise(
            '<strong>Deleting is forever.</strong><br><br>Type <strong>'+name+'</strong> to continue:',
            {
                input: true,
                textOk: 'Delete '+name+' forever'
            },
            function(r) {
                if (r == name) {
                    model.destroy();
                } else {
                    apprise('<strong>Phew. That was close.</strong><br><br>'+name+' was not deleted.');
                }
            }
        );
    }
});
