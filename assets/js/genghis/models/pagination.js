define(['underscore', 'backbone.giraffe', 'genghis/models'], function(_, Giraffe, Models) {

    return Models.Pagination = Giraffe.Model.extend({

        defaults: {
            page:  1,
            pages: 1,
            limit: 50,
            count: 0,
            total: 0
        },

        initialize: function() {
            _.bindAll(this, 'decrementTotal');
        },

        decrementTotal: function() {
            this.set({
                total: this.get('total') - 1,
                count: this.get('count') - 1
            });
        }
    });
});
