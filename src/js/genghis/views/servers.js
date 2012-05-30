Genghis.Views.Servers = Genghis.Base.SectionView.extend({
    el: 'section#servers',
    template: Genghis.Templates.Servers,
    rowView: Genghis.Views.ServerRow,
    updateTitle: function() {
        //noop
    }
});