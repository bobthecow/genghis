Genghis.Models.Collection = Genghis.Models.BaseModel.extend({
    indexesIsPlural: function() {
        return this.indexCount() !== 1;
    },
    indexCount: function() {
        return (this.get('indexes') || []).length;
    },
    indexes: function() {
        return _.map(this.get('indexes'), function(index) {
            return Genghis.JSON.prettyPrint(index.key);
        });
    },
    isGridCollection: function() {
        return (/\.files$/).test(this.get('name'));
    },
    humanSize: function() {
        var stats = this.get('stats');
        if (stats) {
            return Genghis.Util.humanizeSize((stats.storageSize || 0) + (stats.totalIndexSize || 0));
        }
    },
    stats: function() {
        var _h    = Genghis.Util.humanizeSize;
        var stats = this.get('stats');
        if (stats) {
            return [
                {name: 'Avg. object size', value: _h(stats.avgObjSize || 0) },
                {name: 'Padding factor',   value: stats.paddingFactor       },
                {name: 'Data size',        value: _h(stats.size || 0)       },
                {name: 'Index size',       value: _h(stats.totalIndexSize)  },
                {name: 'Storage size',     value: _h(stats.storageSize)     }
            ];
        }
    }
});
