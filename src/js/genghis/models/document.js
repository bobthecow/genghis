Genghis.Models.Document = Backbone.Model.extend({
    initialize: function() {
        _.bindAll(this, 'prettyPrint', 'JSONish');

        var id = this.get('_id');
        if (id) {
            this.id = id['$id'] || id['$oid'] || id;
        }
    },
    parse: function(resp) {
        // a little bitta id thunk.
        if (resp['_id']) {
            this.id = resp['_id']['$id'] || resp['_id']['$oid'] || resp['_id'];
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
        return Genghis.Util.formatJSON(this.toJSON());
    },
    JSONish: function() {
        return JSON.stringify(this.toJSON(), null, 4);
    },
    readOnly: function() {
        return Genghis.features.readOnly || false;
    }
});
