Genghis.Models.Database = Genghis.Models.BaseModel.extend({
    firstChildren: function() {
        return _.first((this.get('collections') || []), 15);
    }
});
