Genghis.Models.Document = Backbone.Model.extend({
    initialize: function() {
        _.bindAll(this, 'prettyId', 'prettyTime', 'prettyPrint', 'JSONish');

        var id = this.thunkId(this.get('_id'));
        if (id) {
            this.id = id;
        }
    },
    thunkId: function(id) {
        if (_.isObject(id) && id.hasOwnProperty('$genghisType') && id['$genghisType'] == 'ObjectId') {
            return id['$value'];
        } else if (typeof id !== 'undefined') {
            return '~' + Genghis.Util.base64Encode(JSON.stringify(id));
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
    prettyId: function() {
        var id = this.get('_id');
        if (_.isObject(id) && id.hasOwnProperty('$genghisType')) {
            switch (id['$genghisType']) {
                case 'ObjectId':
                    return id['$value'];

                case 'BinData':
                    // Special case: UUID
                    if (id['$value']['$subtype'] == 3) {
                        var uuid = /^([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})$/i;
                        var hex  = Genghis.Util.base64ToHex(id['$value']['$binary']);
                        if (uuid.test(hex)) {
                            return hex.replace(uuid, '$1-$2-$3-$4-$5');
                        }
                    }

                    return id['$value']['$binary'].replace(/\=+$/, '');
            }
        }

        // Make null and hash IDs prettier
        return Genghis.JSON.stringify(id, false);
    },
    prettyTime: function() {
        if (!this.collection || this.collection.guessCreationTime) {
            if (typeof this._prettyTime == 'undefined') {
                var id = this.get('_id');
                if (_.isObject(id) && id.hasOwnProperty('$genghisType')) {
                    if (id['$genghisType'] === 'ObjectId' && id['$value'].length == 24) {
                        var time = new Date();
                        time.setTime(parseInt(id['$value'].substring(0,8), 16) * 1000);

                        this._prettyTime = time.toUTCString();
                    }
                }
            }

            return this._prettyTime;
        }
    },
    prettyPrint: function() {
        return Genghis.JSON.prettyPrint(this.toJSON());
    },
    JSONish: function() {
        return Genghis.JSON.stringify(this.toJSON());
    }
});
