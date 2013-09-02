define([
    'jquery', 'underscore', 'backbone', 'mousetrap', 'genghis/util', 'genghis/json', 'genghis/defaults',
    'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/search'
], function($, _, Backbone, Mousetrap, Util, GenghisJSON, defaults, View, Views, template) {

    return Views.Search = View.extend({
        tagName:   'form',
        className: 'navbar-search navbar-form navbar-left',
        template:  template,
        events: {
            'keyup input#navbar-query': 'handleSearchKeyup',
            'click span.grippie':       'toggleExpanded',
            'click button.cancel':      'collapseSearch',
            'click button.search':      'findDocumentsAdvanced',
            'click button.explain':     'explainQuery'
        },

        initialize: function() {
            _.bindAll(
                this, 'render', 'updateQuery', 'handleSearchKeyup', 'findDocuments', 'findDocumentsAdvanced', 'focusSearch', 'blurSearch',
                'advancedSearchToQuery', 'queryToAdvancedSearch', 'expandSearch', 'collapseSearch', 'collapseNoFocus', 'toggleExpanded'
            );

            this.model.bind('change',            this.updateQuery);
            this.model.bind('change:collection', this.collapseNoFocus);
        },

        render: function() {
            this.$el.html(this.template({query: this.model.get('query')}));

            // TODO: remove after wiring up UI hash
            this.$query = this.$('input#navbar-query');
            this.$well  = this.$('.well');

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

            this.$query.val(q);
        },

        getDocumentQuery: function() {
            var q = this.model.get('document');
            if (_.isString(q) && q[0] === '~') {
                q = GenghisJSON.normalize('{"_id":' + Util.decodeDocumentId(q) + '}');
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

        findDocuments: function(q, section) {
            section = section || 'documents';
            var url = Util.route(this.model.currentCollection.url + '/' + section);

            q = q.trim();
            if (section === 'documents' && q.match(/^([a-z\d]+)$/i)) {
                url = url + '/' + q;
            } else {
                try {
                    q = GenghisJSON.normalize(q, false);
                } catch (e) {
                    this.$el.addClass('error');
                    return;
                }

                url = url + '?' + Util.buildQuery({q: encodeURIComponent(q)});
            }

            app.router.navigate(url, true);
        },

        findDocumentsAdvanced: function(e) {
            this.findDocuments(this.editor.getValue());
            this.collapseSearch();
        },

        explainQuery: function(e) {
            this.findDocuments(this.editor.getValue(), 'explain');
            this.collapseSearch();
        },

        focusSearch: function(e) {
            // TODO: make the view stateful rather than querying the DOM
            if (this.$query.is(':visible')) {
                if (e) e.preventDefault();
                this.$query.focus();
            } else if (this.editor && this.$well.is(':visible')) {
                if (e) e.preventDefault();
                this.editor.focus();
            }
        },

        blurSearch: function() {
            this.$query.blur();
            this.updateQuery();
        },

        normalizeQuery: function(q) {
            q = q.trim();

            if (q !== '') {
                try {
                    q = GenghisJSON.normalize(q, false);
                } catch (e) {
                    // do nothing, we'll use the un-normalized version.
                }
            }

            return q.replace(/^\{\s*\}$/, '')
                    .replace(/^\{\s*(['"]?)_id\1\s*:\s*\{\s*(['"]?)\$id\2\s*:\s*(["'])([a-z\d]+)\3\s*\}\s*\}$/, '$4')
                    .replace(/^\{\s*(['"]?)_id\1\s*:\s*(new\s+)?ObjectId\s*\(\s*(["'])([a-z\d]+)\3\s*\)\s*\}$/, '$4');
        },

        advancedSearchToQuery: function() {
            this.$query.val(this.normalizeQuery(this.editor.getValue()));
        },

        queryToAdvancedSearch: function() {
            var q = this.$query.val().trim();

            if (q.match(/^[a-z\d]+$/i)) {
                q = '{_id:ObjectId("'+q+'")}';
            }

            if (q !== '') {
                try {
                    q = GenghisJSON.normalize(q, true);
                } catch (e) {
                    // Do nothing, we'll copy over the broken JSON
                }
            }

            this.editor.setValue(q);
        },

        expandSearch: function(expand) {
            if (!this.editor) {
                var wrapper = this.$('.search-advanced');
                this.editor = CodeMirror(this.$well[0], _.extend({}, defaults.codeMirror, {
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
        }
    });
});
