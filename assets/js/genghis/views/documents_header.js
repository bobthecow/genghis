define(['underscore', 'backbone', 'genghis/views'], function(_, Backbone, Views) {

    return Views.DocumentsHeader = Backbone.View.extend({
        el: 'section#documents > header h2',

        initialize: function() {
            _.bindAll(this, 'render');
            this.model.bind('change', this.render);
        },

        render: function() {
            var title;
            var count = this.model.get('count');
            var page  = this.model.get('page');
            var pages = this.model.get('pages');
            var limit = this.model.get('limit');
            var total = this.model.get('total');

            // n - m of c documents
            title = '' + total + ' Document' + (total != 1 ? 's' : '');
            if (total != count) {
                var from = ((page - 1) * limit) + 1;
                var to   = Math.min((((page - 1) * limit) + count), total);
                title = '' + from + ' - ' + to + ' of ' + title;
            }

            this.$el.html(title);
            return this;
        }
    });
});
