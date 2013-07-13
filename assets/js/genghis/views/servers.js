define([
    'jquery', 'genghis/views', 'genghis/views/base_section', 'genghis/views/server_row', 'hgn!genghis/templates/servers', 'bootstrap.tooltip'
], function($, Views, BaseSection, ServerRow, template, _1) {

    return Views.Servers = BaseSection.extend({
        el:       'section#servers',
        template: template,
        rowView:  ServerRow,

        render: function() {
            BaseSection.prototype.render.apply(this, arguments);

            // add placeholder help
            $('.help', this.addForm).tooltip();

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
