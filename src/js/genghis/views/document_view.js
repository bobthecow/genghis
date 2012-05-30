Genghis.Views.DocumentView = Backbone.View.extend({
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
        var $dbRef = $(e.target).parents('.db-ref'),
            db     = $dbRef.find('.db-ref-db .value').text();

        App.Router.redirectToDatabase(Genghis.Selection.CurrentServer.id, db);
    },
    navigateColl: function(e) {
        var $dbRef = $(e.target).parents('.db-ref'),
            db     = $dbRef.find('.db-ref-db  .value').text() || Genghis.Selection.CurrentDatabase.id,
            coll   = $dbRef.find('.db-ref-ref .value').text();

        App.Router.redirectToCollection(Genghis.Selection.CurrentServer.id, db, coll);
    },
    navigateId: function(e) {
        var $dbRef = $(e.target).parents('.db-ref'),
            db     = $dbRef.find('.db-ref-db  .value').text() || Genghis.Selection.CurrentDatabase.id,
            coll   = $dbRef.find('.db-ref-ref .value').text() || Genghis.Selection.CurrentCollection.id,
            id     = $dbRef.find('.db-ref-id  .value').text();

        App.Router.redirectToDocument(Genghis.Selection.CurrentServer.id, db, coll, id);
    },
    openEditDialog: function() {
        var $well = this.$('.well'),
            height = Math.max(180, Math.min(600, $well.height() + 40));

        $(this.el).addClass('edit');
        $well.height(height);

        var div = $('<div id="editor-'+this.model.id+'" class="genghis-document-editor"></div>')
            .text(this.model.JSONish())
            .appendTo($well)
            .height(height);


        this.$('.document').hide();

        this.editor = ace.edit('editor-'+this.model.id);
        this.editor.setTheme("ace/theme/git-hubby");
        this.editor.setHighlightActiveLine(false);
        this.editor.setShowPrintMargin(false);
        this.editor.renderer.setShowGutter(false);

        var JsonMode = require("ace/mode/json").Mode;
        this.editor.getSession().setMode(new JsonMode());

        div.resize(_.throttle(this.editor.resize, 100));
    },
    cancelEdit: function() {
        $(this.el).removeClass('edit');
        this.editor.destroy();
        this.$('.genghis-document-editor').remove();
        this.updateDocument();
        this.$('.well').height('auto');
    },
    saveDocument: function() {
        var doc = this.model,
            cancelEdit = this.cancelEdit;

        $.ajax({
            type: 'POST',
            url: Genghis.baseUrl + 'convert-json',
            data: this.editor.getSession().getValue(),
            contentType: 'application/json',
            async: false,
            success: function(data) {
                doc.clear({silent: true});
                doc.set(data);
                doc.save();
                cancelEdit();
            },
            dataType: 'json'
        });
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
