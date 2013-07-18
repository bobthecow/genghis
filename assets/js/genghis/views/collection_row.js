define([
    'genghis/views', 'genghis/views/row', 'genghis/views/confirm', 'hgn!genghis/templates/collection_row'
], function(Views, Row, Confirm, template) {

    return Views.CollectionRow = Row.extend({
        template:   template,
        isParanoid: true,

        events: _.extend({
            'click button.truncate': 'truncate'
        }, Row.prototype.events),

        truncate: function() {
            var model = this.model;
            var name  = model.get('name');
            var count = model.get('count') || 'all';

            new Confirm({
                header: 'Remove all documents?',
                body:   'Emptying this collection will remove <strong>' + count + ' documents</strong>, but will leave indexes intact.' +
                        '<br><br>Type <strong>' + name + '</strong> to continue:',
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
});
