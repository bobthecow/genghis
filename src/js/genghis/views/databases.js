Genghis.Views.Databases = Genghis.Views.BaseSection.extend({
    el: 'section#databases',
    template: Genghis.Templates.Databases,
    rowView: Genghis.Views.DatabaseRow,
    formatTitle: function(model) {
        return model.id ? (model.id + ' Databases') : 'Databases';
    }
});
