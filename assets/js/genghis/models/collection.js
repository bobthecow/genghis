define([
    'underscore', 'backbone-stack', 'genghis/models', 'genghis/models/base_model', 'genghis/json', 'genghis/util'
], function(_, Backbone, Models, BaseModel, GenghisJSON, Util) {

    return Models.Collection = BaseModel.extend({

        indexesIsPlural: function() {
            return this.indexCount() !== 1;
        },

        indexCount: function() {
            return (this.get('indexes') || []).length;
        },

        indexes: function() {
            return _.map(this.get('indexes'), function(index) {
                return GenghisJSON.prettyPrint(index.key);
            });
        },

        isGridCollection: function() {
            return (/\.files$/).test(this.get('name'));
        },

        humanSize: function() {
            var stats = this.get('stats');
            if (stats) {
                return Util.humanizeSize((stats.storageSize || 0) + (stats.totalIndexSize || 0));
            }
        },

        stats: function() {
            var _h    = Util.humanizeSize;
            var stats = this.get('stats');
            if (stats) {
                return [
                    {name: 'Avg. object size', value: _h(stats.avgObjSize || 0)     },
                    {name: 'Padding factor',   value: stats.paddingFactor || 'n/a'  },
                    {name: 'Data size',        value: _h(stats.size || 0)           },
                    {name: 'Index size',       value: _h(stats.totalIndexSize || 0) },
                    {name: 'Storage size',     value: _h(stats.storageSize || 0)    }
                ];
            }
        },

        truncate: function(options) {
            options = options ? _.clone(options) : {};
            var model = this;
            var success = options.success;

            var truncate = function() {
                model.trigger('truncate', model, model.collection, options);
            };

            options.success = function(resp) {
                if (options.wait || model.isNew()) truncate();
                if (success) success(model, resp, options);
                if (!model.isNew()) model.trigger('sync', model, resp, options);
            };

            options.url = this.url() + '/documents';

            if (this.isNew()) {
                options.success();
                return false;
            }

            var error = options.error;
            options.error = function(resp) {
                if (error) error(model, resp, options);
                model.trigger('error', model, resp, options);
            };

            var xhr = this.sync('delete', this, options);
            if (!options.wait) truncate();
            return xhr;
        }
    });
});
