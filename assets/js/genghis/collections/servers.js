define(['underscore', 'backbone.giraffe', 'genghis/collections', 'genghis/models/server'], function(_, Giraffe, Collections, Server) {

    return Collections.Servers = Giraffe.Collection.extend({
        model: Server,
        firstChildren: function() {
            return this.collection.reject(function(m) { return m.has('error'); }).slice(0, 10);
        },
        hasMoreChildren: function() {
            return this.collection.length > 10 || this.collection.detect(function(m) { return m.has('error'); });
        }
    });
});
