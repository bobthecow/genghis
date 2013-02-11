Genghis.Models.Collection = Genghis.Models.BaseModel.extend({
    indexesIsPlural: function() {
        return this.indexCount() !== 1;
    },
    indexCount: function() {
        return (this.get('indexes') || []).length;
    },
    indexes: function() {
        return _.map(this.get('indexes'), function(index) {
            return Genghis.JSON.prettyPrint(index.key);
        });
    },
    isGridCollection: function() {
        return (/\.files$/).test(this.get('name'));
    }
});
