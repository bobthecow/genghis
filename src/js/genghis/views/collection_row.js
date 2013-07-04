Genghis.Views.CollectionRow = Genghis.Views.BaseRow.extend({
    template: Genghis.Templates.CollectionRow,
    isParanoid: true,
    events: _.extend({
        'click button.truncate': 'truncate'
    }, Genghis.Views.BaseRow.prototype.events),
    truncate: function() {
        var model = this.model;
        var name  = model.get('name');

        new Genghis.Views.Confirm({
            header: 'Remove all documents?',
            body:   'Emptying this collection will remove all documents, but will leave indexes intact.' +
                    '<br><br>Type <strong>'+name+'</strong> to continue:',
            confirmInput: name,
            confirmText:  'Empty '+name,
            confirm: function() {
                model.truncate({
                    wait: true,
                    success: function() {
                        model.fetch();
                    }
                });
            }
        });
    }
});
