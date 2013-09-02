define([
    'jquery', 'genghis/views', 'genghis/views/section', 'genghis/views/server_row', 'hgn!genghis/templates/servers', 'bootstrap.tooltip'
], function($, Views, Section, ServerRow, template, _1) {

    return Views.Servers = Section.extend({
        el:       'section#servers',
        template: template,
        rowView:  ServerRow,

        render: function() {
            Section.prototype.render.apply(this, arguments);

            // add placeholder help
            $('.help', this.addForm).tooltip({container: 'body'});

            return this;
        },

        submitAddForm: function() {
            var alerts = this.app.alerts;

            this.collection.create({url: this.addInput.val()}, {
                wait:    true,
                success: this.closeAddForm,
                error:   function(model, response) {
                    alerts.handleError(response);
                }
            });
        },

        updateTitle: function() {
            //noop
        },

        formatTitle: function() {
            return 'Servers';
        }
    });
});
