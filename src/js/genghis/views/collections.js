Genghis.Views.Collections = Genghis.Views.BaseSection.extend({
    el: 'section#collections',
    template: Genghis.Templates.Collections,
    rowView: Genghis.Views.CollectionRow,
    formatTitle: function(model) {
        return model.id ? (model.id + ' Collections') : 'Collections';
    }
});
