Genghis.Views.Pagination = Backbone.View.extend({
    template: _.template($('#pagination-template').html()),
    events: {
        'click a': 'navigate'
    },
    initialize: function() {
        _.bindAll(this, 'render', 'urlTemplate', 'navigate', 'nextPage', 'prevPage');
        this.model.bind('change', this.render);
        $(document).bind('keyup', 'n', this.nextPage);
        $(document).bind('keyup', 'p', this.prevPage);
    },
    render: function() {
        if (this.model.get('pages') == 1) {
            $(this.el).hide();
        } else {
            var count = 9,
                half  = Math.ceil(count / 2),
                page  = this.model.get('page'),
                pages = this.model.get('pages'),
                min   = (page > half) ? Math.max(page - (half - 3), 1) : 1,
                max   = (pages - page > half) ? Math.min(page + (half - 3), pages) : pages,
                start = (max == pages) ? Math.max(pages - (count - 3), 1) : min,
                end   = (min == 1) ? Math.min(start + (count - 3), pages) : max;

            if (end >= pages - 2) {
                end = pages;
            }
            if (start <= 3) {
                start = 1;
            }

            var urlTemplate = this.urlTemplate();
            $(this.el).html(this.template(_.extend(
                this.model.toJSON(),
                {
                    page:  page,
                    pages: pages,
                    start: start,
                    end:   end,
                    prev:  Math.max(1, page - 1),
                    next:  Math.min(page + 1, pages),
                    url:   function(page) { return urlTemplate.replace('{{ page }}', page); }
                }
            ))).show();
        }
        return this;
    },
    urlTemplate: function() {
        var url    = this.collection.url,
            chunks = url.split('?'),
            base   = chunks.shift(),
            params = Genghis.Util.parseQuery(chunks.join('?'));

        return base + '?' + Genghis.Util.buildQuery(_.extend(params, {page: '{{ page }}'}));
    },
    navigate: function(e) {
        e.preventDefault();
        var url = $(e.target).attr('href');
        if (url) {
            App.Router.navigate(Genghis.Util.route(url), true);
        }
    },
    nextPage: function(e) {
        if ($(this.el).is(':visible')) {
            e.preventDefault();
            this.$('li.next a[href]').click();
        }
    },
    prevPage: function(e) {
        if ($(this.el).is(':visible')) {
            e.preventDefault();
            this.$('li.prev a[href]').click();
        }
    }
});