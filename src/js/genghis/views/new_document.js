Genghis.Views.NewDocument = Backbone.View.extend({
    el: '#new-document',
    template: _.template($('#new-document-template').html()),
    initialize: function() {
        _.bindAll(this, 'render', 'show', 'resizeEditor', 'closeModal', 'cancelEdit', 'saveDocument');
        this.render();
    },
    render: function() {
        this.el = $(this.template()).hide().appendTo('body');

        this.modal = this.el.modal('hide');
        this.modal.bind('hide', this.cancelEdit);

        this.editor = ace.edit('editor-new');
        this.editor.setTheme("ace/theme/git-hubby");
        this.editor.setHighlightActiveLine(false);
        this.editor.setShowPrintMargin(false);
        this.editor.renderer.setShowGutter(false);

        var JsonMode = require("ace/mode/json").Mode;
        this.editor.getSession().setMode(new JsonMode());

        $(window).resize(_.throttle(this.resizeEditor, 100));
        this.modal.bind('shown', this.resizeEditor);
        this.modal.find('button.cancel').bind('click', this.closeModal);
        this.modal.find('button.save').bind('click', this.saveDocument);

        return this;
    },
    show: function() {
        this.el.find('#editor-new').height($(window).height() - 250);
        this.editor.getSession().setValue("{\n    \n}\n");
        this.modal.css({marginTop: (30 - (this.el.height() / 2)) + 'px'}).modal('show');
    },
    resizeEditor: function() {
        this.editor.resize();
    },
    closeModal: function(e) {
        this.modal.modal('hide');
    },
    cancelEdit: function(e) {
        this.editor.getSession().setValue('');
    },
    saveDocument: function() {
        var collection = this.collection,
            closeModal = this.closeModal;

        $.ajax({
            type: 'POST',
            url: Genghis.baseUrl + 'convert-json',
            data: this.editor.getSession().getValue(),
            contentType: 'application/json',
            async: false,
            success: function(data) {
                collection.create(data, {success: function(doc) {
                    closeModal();
                    App.Router.navigate(Genghis.Util.route(doc.url()), true);
                }});
            },
            dataType: 'json'
        });
    }
});
