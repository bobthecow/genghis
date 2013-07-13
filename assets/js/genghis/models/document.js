define(['underscore', 'backbone', 'genghis/models', 'genghis/util', 'genghis/json'], function(_, Backbone, Models, Util, GenghisJSON) {

    return Models.Document = Backbone.Model.extend({

        idAttribute: null,

        initialize: function() {
            _.bindAll(this, 'prettyId', 'prettyTime', 'prettyPrint', 'JSONish', 'isGridFile', 'isGridChunk', 'downloadUrl', 'fileUrl');
        },

        parse: function(resp) {
            // a little bitta id thunk.
            var id = Util.encodeDocumentId(resp._id);
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
                switch (id.$genghisType) {
                    case 'ObjectId':
                        return id.$value;

                    case 'BinData':
                        // Special case: UUID
                        if (id.$value.$subtype == 3) {
                            var uuid = /^([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})$/i;
                            var hex  = Util.base64ToHex(id.$value.$binary);
                            if (uuid.test(hex)) {
                                return hex.replace(uuid, '$1-$2-$3-$4-$5');
                            }
                        }

                        return id.$value.$binary.replace(/\=+$/, '');
                }
            }

            // Make null and hash IDs prettier
            return GenghisJSON.stringify(id, false);
        },

        prettyTime: function() {
            if (!this.collection || this.collection.guessCreationTime) {
                if (typeof this._prettyTime == 'undefined') {
                    var id = this.get('_id');
                    if (_.isObject(id) && id.hasOwnProperty('$genghisType')) {
                        if (id.$genghisType === 'ObjectId' && id.$value.length == 24) {
                            var time = new Date();
                            time.setTime(parseInt(id.$value.substring(0,8), 16) * 1000);

                            this._prettyTime = time.toUTCString();
                        }
                    }
                }

                return this._prettyTime;
            }
        },

        prettyPrint: function() {
            return GenghisJSON.prettyPrint(this.toJSON());
        },

        JSONish: function() {
            return GenghisJSON.stringify(this.toJSON());
        },

        isGridFile: function() {
            // define grid files as: in a grid collection and has a chunkSize
            return this.get('chunkSize') && /\.files\/documents\//.test(this.url());
        },

        isGridChunk: function() {
            // define grid files as: in a grid chunks collection and has a files_id
            return this.get('files_id') && /\.chunks\/documents\//.test(this.url());
        },

        downloadUrl: function() {
            if (!this.isGridFile()) {
                throw 'Not a GridFS file.';
            }

            return this.url().replace(/\.files\/documents\//, '.files/files/');
        },

        fileUrl: function() {
            if (!this.isGridChunk()) {
                throw 'Not a GridFS chunk.';
            }

            return this.url()
                .replace(/\.chunks\/documents\//, '.files/documents/')
                .replace(this.id, Util.encodeDocumentId(this.get('files_id')));
        }
    });
});
