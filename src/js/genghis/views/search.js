Genghis.Views.Search = Backbone.View.extend({
    tagName: 'form',
    className: 'navbar-search form-search',
    template: Genghis.Templates.Search,
    events: {
        'keyup input#navbar-query': 'findDocuments',
        // 'click button.search':      'toggleSearch',
    },
    initialize: function() {
        _.bindAll(
            this, 'render', 'updateQuery', 'findDocuments', 'focusSearch'
        );

        this.model.bind('change', this.updateQuery);
    },
    render: function() {
        $(this.el).html(this.template.render({query: this.model.get('query')}));
        $(this.el).submit(function(e) { e.preventDefault(); });

        $(document).bind('keyup', '/', this.focusSearch);

        return this;
    },
    updateQuery: function() {
        var q = (this.model.get('query') || this.model.get('document') || '')
                .trim()
                .replace(/^\{\s*\}$/, '')
                .replace(/^\{\s*(['"]?)_id\1\s*:\s*\{\s*(['"]?)\$id\2\s*:\s*(["'])([a-z\d]+)\3\s*\}\s*\}$/, '$4');

        this.$('input#navbar-query').val(q);
    },
    findDocuments: function(e) {
        if (e.keyCode == 13) {
            e.preventDefault();

            var q    = $(e.target).val();
            var base = Genghis.Util.route(this.model.CurrentCollection.url + '/documents');
            var url  = base + (q.match(/^([a-z\d]+)$/i) ? '/' + q : '?' + Genghis.Util.buildQuery({q: encodeURIComponent(q)}));

            App.Router.navigate(url, true);
        } else if (e.keyCode == 27) {
            this.$('input#navbar-query').blur();
            this.updateQuery();
        }
    },
    focusSearch: function(e) {
        if (this.$('input#navbar-query').is(':visible')) {
            e.preventDefault();
            this.$('input#navbar-query').focus();
        }
    }
});
