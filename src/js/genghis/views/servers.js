Genghis.Views.Servers = Genghis.Views.BaseSection.extend({
    el: 'section#servers',
    template: Genghis.Templates.Servers,
    rowView: Genghis.Views.ServerRow,
    render: function() {
        Genghis.Views.BaseSection.prototype.render.apply(this, arguments);

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
