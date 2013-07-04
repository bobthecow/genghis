Genghis.Views.Search = Backbone.View.extend({
    tagName: 'form',
    className: 'navbar-search form-search control-group',
    template: Genghis.Templates.Search,
    events: {
        'keyup input#navbar-query': 'handleSearchKeyup',
        'click span.grippie':       'toggleExpanded',
        'dragmove span.grippie':    'handleGrippieDrag',
        'click button.cancel':      'collapseSearch',
        'click button.search':      'findDocumentsAdvanced'
    },
    initialize: function() {
        _.bindAll(
            this, 'render', 'updateQuery', 'handleSearchKeyup', 'findDocuments', 'findDocumentsAdvanced', 'focusSearch', 'blurSearch',
            'advancedSearchToQuery', 'queryToAdvancedSearch', 'expandSearch', 'collapseSearch', 'collapseNoFocus', 'toggleExpanded',
            'handleGrippieDrag'
        );

        this.model.bind('change', this.updateQuery);
        this.model.bind('change:collection', this.collapseNoFocus);
    },
    render: function() {
        this.$el.html(this.template.render({query: this.model.get('query')}));
        this.$el.submit(function(e) { e.preventDefault(); });

        Mousetrap.bind('/', this.focusSearch);

        var wrapper   = this.$el;
        var resizable = wrapper.find('.well');
        var expand    = this.expandSearch;
        var collapse  = this.collapseSearch;
        this.$('.grippie').bind('mousedown', function(e) {
            e.preventDefault();

            var minHeight = 30;
            var maxHeight = Math.min($(window).height() / 2, 350);
            $(document).mousemove(mouseMove).mouseup(mouseUp);

            function mouseMove(e) {
                var mouseY = e.clientY + document.documentElement.scrollTop - wrapper.offset().top;

                if (mouseY >= minHeight && mouseY <= maxHeight) {
                    wrapper.height(mouseY + 'px');
                }

                if (wrapper.hasClass('expanded')) {
                    if (mouseY < minHeight) {
                        collapse();
                    }
                } else {
                    if (mouseY > 100) {
                        expand();
                    }
                }

                return false;
            }

            function mouseUp(e) {
                $(document).unbind('mousemove', mouseMove).unbind('mouseup', mouseUp);
                if (!wrapper.hasClass('expanded')) {
                    collapse();
                }
                e.preventDefault();
            }
        });

        return this;
    },
    updateQuery: function() {
        var q = this.normalizeQuery(this.model.get('query') || this.getDocumentQuery() || '');

        this.$('input#navbar-query').val(q);
    },
    getDocumentQuery: function() {
        var q = this.model.get('document');
        if (_.isString(q) && q[0] === '~') {
            q = Genghis.JSON.normalize('{"_id":' + Genghis.Util.decodeDocumentId(q) + '}');
        }

        return q;
    },
    handleSearchKeyup: function(e) {
        this.$el.removeClass('error');

        if (e.keyCode == 13) {
            e.preventDefault();
            this.findDocuments($(e.target).val());
        } else if (e.keyCode == 27) {
            this.blurSearch();
        }
    },
    findDocuments: function(q) {
        var url = Genghis.Util.route(this.model.currentCollection.url + '/documents');

        q = q.trim();
        if (q.match(/^([a-z\d]+)$/i)) {
            url = url + '/' + q;
        } else {
            try {
                q = Genghis.JSON.normalize(q, false);
            } catch (e) {
                this.$el.addClass('error');
                return;
            }

            var explain = this.$el.find('input[name="explain"]').prop('checked');
            url = url + '?' + Genghis.Util.buildQuery({q: encodeURIComponent(q), explain: explain});
        }

        app.router.navigate(url, true);
    },
    findDocumentsAdvanced: function(e) {
        this.findDocuments(this.editor.getValue());
        this.collapseSearch();
    },
    focusSearch: function(e) {
        // TODO: make the view stateful rather than querying the DOM
        if (this.$('input#navbar-query').is(':visible')) {
            if (e) e.preventDefault();
            this.$('input#navbar-query').focus();
        } else if (this.editor && this.$('.well').is(':visible')) {
            if (e) e.preventDefault();
            this.editor.focus();
        }
    },
    blurSearch: function() {
        this.$('input#navbar-query').blur();
        this.updateQuery();
    },
    normalizeQuery: function(q) {
        q = q.trim();

        if (q !== '') {
            try {
                q = Genghis.JSON.normalize(q, false);
            } catch (e) {
                // do nothing, we'll use the un-normalized version.
            }
        }

        return q.replace(/^\{\s*\}$/, '')
                .replace(/^\{\s*(['"]?)_id\1\s*:\s*\{\s*(['"]?)\$id\2\s*:\s*(["'])([a-z\d]+)\3\s*\}\s*\}$/, '$4')
                .replace(/^\{\s*(['"]?)_id\1\s*:\s*(new\s+)?ObjectId\s*\(\s*(["'])([a-z\d]+)\3\s*\)\s*\}$/, '$4');
    },
    advancedSearchToQuery: function() {
        this.$('input#navbar-query').val(this.normalizeQuery(this.editor.getValue()));
    },
    queryToAdvancedSearch: function() {
        var q = this.$('input#navbar-query').val().trim();

        if (q.match(/^[a-z\d]+$/i)) {
            q = '{_id:ObjectId("'+q+'")}';
        }

        if (q !== '') {
            try {
                q = Genghis.JSON.normalize(q, true);
            } catch (e) {
                // Do nothing, we'll copy over the broken JSON
            }
        }

        this.editor.setValue(q);
        var explain = this.model.get('explain');
        this.$('input[name=explain]').prop('checked', explain);
    },
    expandSearch: function(expand) {
        if (!this.editor) {
            var wrapper = this.$('.search-advanced');
            this.editor = CodeMirror(this.$('.well')[0], _.extend({}, Genghis.defaults.codeMirror, {
                lineNumbers: false,
                extraKeys: {
                    'Ctrl-Enter': this.findDocumentsAdvanced,
                    'Cmd-Enter':  this.findDocumentsAdvanced,
                    'Esc':        this.findDocumentsAdvanced
                }
            }));

            this.editor.on('focus', function() { wrapper.addClass('focused');    });
            this.editor.on('blur',  function() { wrapper.removeClass('focused'); });

            this.editor.on('change', this.advancedSearchToQuery);
        }

        this.queryToAdvancedSearch();

        this.$el.addClass('expanded');

        var editor      = this.editor;
        var focusSearch = this.focusSearch;
        _.defer(function() {
            editor.refresh();
            focusSearch();
        });
    },
    collapseSearch: function() {
        this.collapseNoFocus();
        this.focusSearch();
    },
    collapseNoFocus: function() {
        this.$el.removeClass('expanded').css('height', 'auto');
    },
    toggleExpanded: function() {
        if (this.$el.hasClass('expanded')) {
            this.collapseSearch();
        } else {
            this.expandSearch();
            this.$el.height(Math.floor($(window).height() / 4) + 'px');
        }
    },
    handleGrippieDrag: function(e) {
        console.log(e);
    }
});
