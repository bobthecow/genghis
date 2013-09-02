define([
    'jquery', 'underscore', 'backbone', 'mousetrap', 'genghis/views/view', 'genghis/views', 'genghis/util',
    'hgn!genghis/templates/pagination'
], function($, _, Backbone, Mousetrap, View, Views, Util, template) {

    return Views.Pagination = View.extend({
        template: template,
        events: {
            'click a': 'navigate'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'urlTemplate', 'navigate', 'nextPage', 'prevPage');
            this.model.bind('change', this.render);

            Mousetrap.bind('n', this.nextPage);
            Mousetrap.bind('p', this.prevPage);
        },

        render: function() {
            if (this.model.get('pages') == 1) {
                this.$el.hide();
            } else {
                var count = 9;
                var half  = Math.ceil(count / 2);
                var page  = this.model.get('page');
                var pages = this.model.get('pages');
                var min   = (page > half) ? Math.max(page - (half - 3), 1) : 1;
                var max   = (pages - page > half) ? Math.min(page + (half - 3), pages) : pages;
                var start = (max == pages) ? Math.max(pages - (count - 3), 1) : min;
                var end   = (min == 1) ? Math.min(start + (count - 3), pages) : max;

                if (end >= pages - 2) {
                    end = pages;
                }
                if (start <= 3) {
                    start = 1;
                }

                var url = this.urlTemplate;
                this.$el.html(this.template({
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

            // TODO: remove after wiring up UI hash
            this.$next = this.$('li.next a[href]');
            this.$prev = this.$('li.prev a[href]');

            return this;
        },

        urlTemplate: function(i) {
            var url    = this.collection.url;
            var chunks = url.split('?');
            var base   = chunks.shift();
            var params = Util.parseQuery(chunks.join('?'));
            var extra  = {page: i};

            // TODO: this is ugly. fix it.
            if (params.q) {
                // swap out the query for a pretty one
                extra.q = encodeURIComponent(app.selection.get('query'));
            }

            return base + '?' + Util.buildQuery(_.extend(params, extra));
        },

        navigate: function(e) {
            e.preventDefault();
            var url = $(e.target).attr('href');
            if (url) {
                app.router.navigate(Util.route(url), true);
            }
        },

        nextPage: function(e) {
            // TODO: bind/unbind mousetrap so we don't have to check visibilty?
            if (this.$el.is(':visible')) {
                e.preventDefault();
                this.$next.click();
            }
        },

        prevPage: function(e) {
            if (this.$el.is(':visible')) {
                e.preventDefault();
                this.$prev.click();
            }
        }
    });
});
