define(['backbone', 'genghis/collections'], function(Backbone, Collections) {

    return Collections.BaseCollection = Backbone.Collection.extend({
        firstChildren: function() {
            return this.collection.toArray().slice(0, 10);
        },
        hasMoreChildren: function() {
            return this.collection.length > 10;
        }
    });
});
