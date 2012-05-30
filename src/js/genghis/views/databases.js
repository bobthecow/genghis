Genghis.Views.Databases = Genghis.Base.SectionView.extend({
    el: 'section#databases',
    template: Genghis.Templates.Databases,
    rowView: Genghis.Views.DatabaseRow,
    formatTitle: function(model) {
        return model.id ? (model.id + ' databases') : 'Databases';
    }
});
