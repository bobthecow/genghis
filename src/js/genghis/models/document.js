Genghis.Models.Document = Backbone.Model.extend({
    initialize: function() {
        _.bindAll(this, 'prettyPrint', 'JSONish');

        var id = this.thunkId(this.get('_id'));
        if (id) {
            this.id = id;
        }
    },
    thunkId: function(id) {
        if (typeof id === 'object' && id['$genghisType'] == 'ObjectId') {
            return id['$value'];
        } else {
            return id;
        }
    },
    parse: function(resp) {
        // a little bitta id thunk.
        var id = this.thunkId(resp['_id']);
        if (id) {
            this.id = id;
        }

        return resp;
    },
    url: function() {
        var getUrl = function(object) {
            if (!(object && object.url)) return null;
            return _.isFunction(object.url) ? object.url() : object.url;
        };

        var base = getUrl(this.collection) || this.urlRoot || urlError();

        base = base.split('?').shift();

        if (this.isNew()) return base;

        return base + (base.charAt(base.length - 1) == '/' ? '' : '/') + encodeURIComponent(this.id);
    },
    prettyPrint: function() {
        return Genghis.JSON.prettyPrint(this.toJSON());
    },
    JSONish: function() {
        return Genghis.JSON.stringify(this.toJSON());
    }
});
