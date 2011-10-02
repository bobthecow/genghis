Genghis.Views.Servers = Genghis.Base.SectionView.extend({
    el: 'section#servers',
    template: _.template($('#servers-template').html()),
    rowView: Genghis.Views.ServerRow,
    updateTitle: function() {
    	//noop
    }
});