Genghis.Models.Collection = Genghis.Base.Model.extend({
    indexesIsPlural: function() {
        this.indexCount() !== 1;
    },
    indexCount: function() {
        return (this.get('indexes') || []).length !== 1;
    },
    indexes: function() {
        return _.map(this.get('indexes'), function(index) {
            return Genghis.Util.formatJSON(index.key);
        });
    }
});
