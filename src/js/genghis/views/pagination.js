Genghis.Views.Pagination = Backbone.View.extend({
    template: Genghis.Templates.Pagination,
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

            var url = this.urlTemplate;
            $(this.el).html(this.template.render({
                page:     page,
                last:     pages,
                firstUrl: url(1),
                prevUrl:  url(Math.max(1, page - 1)),
                nextUrl:  url(Math.min(page + 1, pages)),
                lastUrl:  url(pages),
                pageUrls: _.range(start, end + 1).map(function(i) {
                    return {
                        index:  i,
                        url:    url(i),
                        active: i === page
                    };
                }),
                isFirst: page === 1,
                isStart: start === 1,
                isEnd:   end >= pages,
                isLast:  page === pages
            })).show();
        }
        return this;
    },
    urlTemplate: function(i) {
        var url    = this.collection.url,
            chunks = url.split('?'),
            base   = chunks.shift(),
            params = Genghis.Util.parseQuery(chunks.join('?'));

        return base + '?' + Genghis.Util.buildQuery(_.extend(params, {page: i}));
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
