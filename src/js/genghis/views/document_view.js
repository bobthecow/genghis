Genghis.Views.DocumentView = Genghis.Base.DocumentView.extend({
    tagName: 'article',
    template: Genghis.Templates.DocumentView,
    events: {
        'click a.id':               'navigate',
        'click button.edit':        'openEditDialog',
        // 'dblclick .document':       'openEditDialog',
        'click button.save':        'saveDocument',
        'click button.cancel':      'cancelEdit',
        'click button.destroy':     'destroy',
        'click .db-ref-ref .value': 'navigateColl',
        'click .db-ref-db .value':  'navigateDb',
        'click .db-ref-id .value':  'navigateId'
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
        setTimeout(this.updateDocument, 1);

        return this;
    },
    updateDocument: function() {
        this.$('.document').html('').append(this.model.prettyPrint()).show();
        Genghis.Util.attachCollapsers(this.el);
    },
    navigate: function(e) {
        e.preventDefault();
        App.Router.navigate(Genghis.Util.route($(e.target).attr('href')), true);
    },
    navigateDb: function(e) {
        var $dbRef = $(e.target).parents('.db-ref');
        var db     = $dbRef.find('.db-ref-db .value').text();

        App.Router.redirectToDatabase(Genghis.Selection.CurrentServer.id, db);
    },
    navigateColl: function(e) {
        var $dbRef = $(e.target).parents('.db-ref');
        var db     = $dbRef.find('.db-ref-db  .value').text() || Genghis.Selection.CurrentDatabase.id;
        var coll   = $dbRef.find('.db-ref-ref .value').text();

        App.Router.redirectToCollection(Genghis.Selection.CurrentServer.id, db, coll);
    },
    navigateId: function(e) {
        var $dbRef = $(e.target).parents('.db-ref');
        var db     = $dbRef.find('.db-ref-db  .value').text() || Genghis.Selection.CurrentDatabase.id;
        var coll   = $dbRef.find('.db-ref-ref .value').text() || Genghis.Selection.CurrentCollection.id;
        var id     = $dbRef.find('.db-ref-id  .value').text();

        App.Router.redirectToDocument(Genghis.Selection.CurrentServer.id, db, coll, id);
    },
    openEditDialog: function() {
        var $well = this.$('.well');
        var height = Math.max(180, Math.min(600, $well.height() + 40));

        $well.height(height);
        var textarea = $('<textarea id="editor-'+this.model.id+'"></textarea>')
            .text(this.model.JSONish())
            .appendTo($well)
            .height(height);

        this.$('.document').hide();

        var el = $(this.el).addClass('edit');
        this.editor = CodeMirror.fromTextArea($('#editor-'+this.model.id)[0], _.extend(Genghis.defaults.codeMirror, {
            onFocus: function() { el.addClass('focused');    },
            onBlur:  function() { el.removeClass('focused'); }
        }));

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
        if (errorBlock.length == 0) {
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
                    model.destroy();
                    Genghis.Selection.Pagination.decrementTotal();
                }
            }
        );
    },
    remove: function() {
        $(this.el).remove();
    }
});
