define([
    'jquery', 'genghis/views', 'genghis/views/section', 'genghis/views/server_row', 'hgn!genghis/templates/servers', 'bootstrap.tooltip'
], function($, Views, Section, ServerRow, template, _1) {

    return Views.Servers = Section.extend({
        el:       'section#servers',
        template: template,
        rowView:  ServerRow,

        // override, since the servers section has no model
        // mebbe this model should be the one that holds user config?
        // who knows...
        modelEvents: null,

        afterRender: function() {
            Section.prototype.afterRender.apply(this, arguments);

            // add placeholder help
            $('.help', this.addForm).tooltip({container: 'body'});
        },

        submitAddForm: function() {
            var alerts = this.app.alerts;

            this.collection.create({url: this.$addInput.val()}, {
                wait:    true,
                success: this.closeAddForm,
                error:   function(model, response) {
                    alerts.handleError(response);
                }
            });
        },

        updateTitle: $.noop,

        formatTitle: function() {
            return 'Servers';
        }
    });
});
