Genghis.Views.Collections = Genghis.Base.SectionView.extend({
    el: 'section#collections',
    template: _.template($('#collections-template').html()),
    rowView: Genghis.Views.CollectionRow,
    formatTitle: function(model) {
        return model.id ? (model.id + ' collections') : 'Collections';
    }
});
