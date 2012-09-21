Genghis.Views.DocumentView = Genghis.Views.BaseDocument.extend({
    tagName: 'article',
    template: Genghis.Templates.DocumentView,
    events: {
        'click a.id':               'navigate',
        'click button.edit':        'openEditDialog',
        // 'dblclick .document':       'openEditDialog',
        'click button.save':        'saveDocument',
        'click button.cancel':      'cancelEdit',
        'click button.destroy':     'destroy',

        // navigation!
        'click .ref .ref-ref .v .s':                    'navigateColl',
        'click .ref .ref-db .v .s':                     'navigateDb',
        'click .ref .ref-id .v .s, .ref .ref-id .v.n':  'navigateId'    // handle numeric IDs too
    },
    initialize: function() {
        _.bindAll(
            this, 'render', 'updateDocument', 'navigate', 'openEditDialog', 'cancelEdit', 'saveDocument', 'destroy',
            'remove', 'navigateColl', 'navigateDb', 'navigateId'
        );

        this.model.bind('change',  this.updateDocument);
        this.model.bind('destroy', this.remove);
    },
    render: function() {
        $(this.el).html(this.template.render(this.model));
        Genghis.Util.attachCollapsers(this.el);
        setTimeout(this.updateDocument, 1);

        return this;
    },
    updateDocument: function() {
        this.$('.document').html('').append(this.model.prettyPrint()).show();
    },
    navigate: function(e) {
        e.preventDefault();
        app.router.navigate(Genghis.Util.route($(e.target).attr('href')), true);
    },
    navigateDb: function(e) {
        var $dbRef = $(e.target).parents('.ref');
        var db     = $dbRef.find('.ref-db .v .s').text();

        app.router.redirectToDatabase(app.selection.currentServer.id, db);
    },
    navigateColl: function(e) {
        var $dbRef = $(e.target).parents('.ref');
        var db     = $dbRef.find('.ref-db  .v .s').text() || app.selection.currentDatabase.id;
        var coll   = $dbRef.find('.ref-ref .v .s').text();

        app.router.redirectToCollection(app.selection.currentServer.id, db, coll);
    },
    navigateId: function(e) {
        var $dbRef = $(e.target).parents('.ref');
        var db     = $dbRef.find('.ref-db  .v .s').text() || app.selection.currentDatabase.id;
        var coll   = $dbRef.find('.ref-ref .v .s').text() || app.selection.currentCollection.id;
        var id     = $dbRef.find('.ref-id  .v .s, .ref-id .v.n').text();

        app.router.redirectToDocument(app.selection.currentServer.id, db, coll, id);
    },
    openEditDialog: function() {
        var $well = this.$('.well');
        var height = Math.max(180, Math.min(600, $well.height() + 40));
        var editorId = 'editor-' + this.model.id.replace('~', '-');

        var textarea = $('<textarea id="'+editorId+'"></textarea>')
            .text(this.model.JSONish())
            .appendTo($well);

        this.$('.document').hide();

        var el = $(this.el).addClass('edit');
        this.editor = CodeMirror.fromTextArea(textarea[0], _.extend(Genghis.defaults.codeMirror, {
            onFocus: function() { el.addClass('focused');    },
            onBlur:  function() { el.removeClass('focused'); },
            extraKeys: {
                 'Ctrl-Enter': this.saveDocument,
                 'Cmd-Enter':  this.saveDocument
             }
        }));

        this.editor.setSize(null, height);

        setTimeout(this.editor.focus, 50);

        textarea.resize(_.throttle(this.editor.refresh, 100));
    },
    cancelEdit: function() {
        $(this.el).removeClass('edit focused');
        this.editor.toTextArea();
        $('textarea', this.el).remove();
        this.updateDocument();
        this.$('.well').height('auto');
    },
    getErrorBlock: function() {
        var errorBlock = this.$('div.errors');
        if (errorBlock.length === 0) {
            errorBlock = $('<div class="errors"></div>').prependTo(this.el);
        }

        return errorBlock;
    },
    saveDocument: function() {
        var data = this.getEditorValue();
        if (data === false) {
            return;
        }

        this.model.clear({silent: true});
        this.model.set(data);
        this.model.save();
        this.cancelEdit();
    },
    destroy: function() {
        var model = this.model;
        apprise(
            'Really? There is no undo.',
            {
                confirm: true,
                textCancel: 'Cancel',
                textOk: '<strong>Yes</strong>, delete document forever'
            },
            function(r) {
                if (r) {
                    var selection = app.selection;

                    model.destroy();

                    selection.pagination.decrementTotal();

                    // if we're currently in single-document view, bust outta this!
                    if (selection.get('document')) {
                        app.router.redirectTo(selection.get('server'), selection.get('database'), selection.get('collection'), null, selection.get('query'));
                    }
                }
            }
        );
    },
    remove: function() {
        $(this.el).remove();
    }
});
