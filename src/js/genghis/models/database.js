Genghis.Models.Database = Genghis.Models.BaseModel.extend({
    firstChildren: function() {
        return _.first((this.get('collections') || []), 15);
    },
    humanSize: function() {
        var stats = this.get('stats');
        if (stats) {
            return Genghis.Util.humanizeSize((stats.fileSize || 0) + (stats.indexSize || 0));
        }
    },
    stats: function() {
        var _h    = Genghis.Util.humanizeSize;
        var stats = this.get('stats');
        if (stats) {
            return [
                {name: 'Avg. object size', value: _h(stats.avgObjSize || 0) },
                {name: 'Data size',        value: _h(stats.dataSize || 0)   },
                {name: 'Index size',       value: _h(stats.indexSize || 0)  },
                {name: 'Storage size',     value: _h(stats.fileSize || 0)   }
            ];
        }
    }
});
