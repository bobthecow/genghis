Genghis.Views.DocumentsHeader = Backbone.View.extend({
    el: 'section#documents > header h2',
    initialize: function() {
        _.bindAll(this, 'render');
        this.model.bind('change', this.render);
    },
    render: function() {
        var title,
            count = this.model.get('count'),
            page  = this.model.get('page'),
            pages = this.model.get('pages'),
            limit = this.model.get('limit'),
            total = this.model.get('total');

        // n - m of c documents
        title = '' + total + ' document' + (total != 1 ? 's' : '');
        if (total != count) {
            var from = ((page - 1) * limit) + 1,
                to   = Math.min((((page - 1) * limit) + count), total);
            title = '' + from + ' - ' + to + ' of ' + title;
        }

        $(this.el).html(title);
        return this;
    }
});