Genghis.Models.Server = Genghis.Base.Model.extend({
    firstChildren: function() {
        return _.first(this.get('databases'), 15);
    },
    error: function() {
    	return this.get('error');
    }
});
