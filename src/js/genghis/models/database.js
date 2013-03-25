Genghis.Models.Database = Genghis.Models.BaseModel.extend({
    firstChildren: function() {
        return _.first((this.get('collections') || []), 15);
    },
    humanSize: function() {
        var stats = this.get('stats');
        if (stats) {
            return Genghis.Util.humanizeSize((stats.fileSize || 0) + (stats.indexSize || 0));
        }
    }
});
