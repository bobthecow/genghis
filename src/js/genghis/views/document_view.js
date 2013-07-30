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
        'click a.grid-download':    'download',
        'click a.grid-file':        'navigate',

        // navigation!
        'click .ref .ref-ref .v .s':                    'navigateColl',
        'click .ref .ref-db .v .s':                     'navigateDb',
        'click .ref .ref-id .v .s, .ref .ref-id .v.n':  'navigateId'    // handle numeric IDs too
    },
    initialize: function() {
        _.bindAll(
            this, 'render', 'updateDocument', 'navigate', 'openEditDialog', 'cancelEdit', 'saveDocument', 'destroy',
            'remove', 'download', 'navigateColl', 'navigateDb', 'navigateId', 'showServerError'
        );

        this.model.bind('change',  this.updateDocument);
        this.model.bind('destroy', this.remove);
    },
    render: function() {
        this.$el.html(this.template.render(this.model));
        Genghis.Util.attachCollapsers(this.el);
        setTimeout(this.updateDocument, 1);

        return this;
    },
    updateDocument: function() {
        this.$('.document').html('').append(this.model.prettyPrint()).show();
    },
    navigate: function(e) {
        if (!e.shiftKey && !e.ctrlKey) {
            e.preventDefault();
            app.router.navigate(Genghis.Util.route($(e.target).attr('href')), true);
        }
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
        var id     = $dbRef.find('.ref-id').attr('data-document-id');

        app.router.redirectToDocument(app.selection.currentServer.id, db, coll, encodeURIComponent(id));
    },
    openEditDialog: function() {
        var $well = this.$('.well');
        var height = Math.max(180, Math.min(600, $well.height() + 40));
        var editorId = 'editor-' + this.model.id.replace('~', '-');

        var textarea = $('<textarea id="'+editorId+'"></textarea>')
            .text(this.model.JSONish())
            .appendTo($well);

        this.$('.document').hide();

        var el = this.$el.addClass('edit');
        this.editor = CodeMirror.fromTextArea(textarea[0], _.extend({}, Genghis.defaults.codeMirror, {
            autofocus: true,
            extraKeys: {
                 'Ctrl-Enter': this.saveDocument,
                 'Cmd-Enter':  this.saveDocument
             }
        }));

        this.editor.on('focus', function() { el.addClass('focused');    });
        this.editor.on('blur',  function() { el.removeClass('focused'); });

        this.editor.setSize(null, height);

        textarea.resize(_.throttle(this.editor.refresh, 100));
    },
    cancelEdit: function() {
        this.$el.removeClass('edit focused');
        this.editor.toTextArea();
        this.$('textarea').remove();
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
    showServerError: function(message) {
        var alertView = new Genghis.Views.Alert({
            model: new Genghis.Models.Alert({level: 'error', msg: message, block: true})
        });

        this.getErrorBlock().append(alertView.render().el);
    },
    saveDocument: function() {
        var data = this.getEditorValue();
        if (data === false) {
            return;
        }

        var showServerError = this.showServerError;

        this.model.clear({silent: true});
        this.model.save(data, {
            wait:    true,
            success: this.cancelEdit,
            error: function(doc, xhr) {
                var msg;
                try {
                    msg = JSON.parse(xhr.responseText).error;
                } catch (e) {
                    // do nothing
                }

                showServerError(msg || 'Error updating document.');
            }
        });
    },
    destroy: function() {
        var model      = this.model;
        var isGridFile = this.model.isGridFile();
        var docType    = isGridFile ? 'file' : 'document';

        if (isGridFile) {
            this.model.url = this.model.url().replace('.files/documents/', '.files/files/');
        }

        new Genghis.Views.Confirm({
            body: '<strong>Really?</strong> ' + (isGridFile ? 'This will delete all GridFS chunks as well. <br><br>' : '') + 'There is no undo.',
            confirmText: '<strong>Yes</strong>, delete ' + docType + ' forever',
            confirm: function() {
                var selection = app.selection;

                model.destroy({
                    wait: true,
                    error: function(doc, xhr) {
                        var msg;
                        try {
                            msg = JSON.parse(xhr.responseText).error;
                        } catch (e) {
                            // do nothing
                        }

                        app.alerts.create({
                            level: 'error',
                            msg: msg || 'Error deleting ' + docType + '.'
                        });
                    },
                    success: function(doc, xhr) {
                        selection.pagination.decrementTotal();

                        // if we're currently in single-document view, bust outta this!
                        if (selection.get('document')) {
                            app.router.redirectTo(selection.get('server'), selection.get('database'), selection.get('collection'), null, selection.get('query'));
                        }
                    }
                });
            }
        });
    },
    remove: function() {
        this.$el.remove();
    },
    download: function(e) {
        Genghis.Util.download(this.model.downloadUrl());
        e.preventDefault();
    }
});
