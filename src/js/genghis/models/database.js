Genghis.Models.Database = Genghis.Base.Model.extend({
    firstChildren: function() {
        return _.first((this.get('collections') || []), 15);
    }
});
