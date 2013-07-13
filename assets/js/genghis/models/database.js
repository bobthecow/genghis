define(['underscore', 'genghis/models', 'genghis/models/base_model', 'genghis/util'], function(_, Models, BaseModel, Util) {

    return Models.Database = BaseModel.extend({

        firstChildren: function() {
            return _.first((this.get('collections') || []), 15);
        },

        humanSize: function() {
            var stats = this.get('stats');
            if (stats) {
                return Util.humanizeSize((stats.fileSize || 0) + (stats.indexSize || 0));
            }
        },

        stats: function() {
            var _h    = Util.humanizeSize;
            var stats = this.get('stats');
            if (stats) {
                return [
                    {name: 'Avg. object size', value: _h(stats.avgObjSize || 0) },
                    {name: 'Data size',        value: _h(stats.dataSize || 0)   },
                    {name: 'Index size',       value: _h(stats.indexSize || 0)  },
                    {name: 'Storage size',     value: _h(stats.fileSize || 0)   }
                ];
            }
        },

        error: function() {
            return this.get('error');
        }
    });
});
