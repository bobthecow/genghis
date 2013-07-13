define(['backbone', 'genghis/models', 'genghis/util'], function(Backbone, Models, Util) {

    return Models.BaseModel = Backbone.Model.extend({

        name: function() {
            return this.get('name');
        },

        count: function() {
            return this.get('count');
        },

        humanCount: function() {
            return Util.humanizeCount(this.get('count') || 0);
        },

        isPlural: function() {
            return this.get('count') !== 1;
        },

        humanSize: function() {
            var size = this.get('size');
            if (size) {
                return Util.humanizeSize(size);
            }
        },

        hasMoreChildren: function() {
            return this.get('count') > 15;
        }
    });
});
