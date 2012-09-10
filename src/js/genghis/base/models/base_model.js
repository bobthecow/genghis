Genghis.Models.BaseModel = Backbone.Model.extend({
    name: function() {
        return this.get('name');
    },
    count: function() {
        return this.get('count');
    },
    humanCount: function() {
        return Genghis.Util.humanizeCount(this.get('count') || 0);
    },
    isPlural: function() {
        return this.get('count') !== 1;
    },
    humanSize: function() {
        return Genghis.Util.humanizeSize(this.get('size'));
    },
    hasMoreChildren: function() {
        return this.get('count') > 15;
    }
});
