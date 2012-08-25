Genghis.Models.Server = Genghis.Base.Model.extend({
    editable: function() {
        return !!this.get('editable');
    },
    firstChildren: function() {
        return _.first((this.get('databases') || []), 15);
    },
    error: function() {
        return this.get('error');
    }
});
