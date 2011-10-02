Genghis.Views.DatabaseRow = Genghis.Base.RowView.extend({
    template: _.template($('#database-row-template').html()),
    destroy: function() {
        var model = this.model;
        apprise(
            '<strong>Deleting is forever.</strong><br><br>Type <strong>DELETE</strong> to continue:',
            {
                input: true,
                textOk: 'Delete '+model.get('name')+' forever'
            },
            function(r) {
                if (r == "DELETE") {
                    model.destroy();
                } else {
                    apprise('<strong>Phew. That was close.</strong><br><br>'+model.get('name')+' was not deleted.');
                }
            }
        );
    }
});
