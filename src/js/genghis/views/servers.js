Genghis.Views.Servers = Genghis.Views.BaseSection.extend({
    el: 'section#servers',
    template: Genghis.Templates.Servers,
    rowView: Genghis.Views.ServerRow,
    updateTitle: function() {
        //noop
    },
    formatTitle: function() {
        return 'Servers';
    }
});
