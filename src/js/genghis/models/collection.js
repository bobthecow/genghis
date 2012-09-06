Genghis.Models.Collection = Genghis.Base.Model.extend({
    indexesIsPlural: function() {
        this.indexCount() !== 1;
    },
    indexCount: function() {
        return (this.get('indexes') || []).length;
    },
    indexes: function() {
        return _.map(this.get('indexes'), function(index) {
            return Genghis.JSON.prettyPrint(index.key);
        });
    }
});
