define(['backbone.giraffe', 'genghis/collections'], function(Giraffe, Collections) {

    return Collections.BaseCollection = Giraffe.Collection.extend({
        firstChildren: function() {
            return this.collection.toArray().slice(0, 10);
        },
        hasMoreChildren: function() {
            return this.collection.length > 10;
        }
    });
});
