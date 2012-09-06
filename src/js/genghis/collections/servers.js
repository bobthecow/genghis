Genghis.Collections.Servers = Backbone.Collection.extend({
    model: Genghis.Models.Server,
    firstChildren: function() {
        return this.collection.reject(function(m) { return m.has('error'); }).slice(0, 10);
    },
    hasMoreChildren: function() {
        return this.collection.length > 10 || this.collection.detect(function(m) { return m.has('error'); });
    }
});
