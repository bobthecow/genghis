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

        updateTitle: function() {
            //noop
        },

        formatTitle: function() {
            return 'Servers';
        }
    });
});
