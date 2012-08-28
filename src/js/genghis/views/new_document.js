Genghis.Views.NewDocument = Backbone.View.extend({
    el: '#new-document',
    template: Genghis.Templates.NewDocument,
    initialize: function() {
        _.bindAll(this, 'render', 'show', 'refreshEditor', 'closeModal', 'cancelEdit', 'saveDocument');
        this.render();
    },
    render: function() {
        var wrapper;

        this.el = $(this.template.render()).hide().appendTo('body');

        this.modal = this.el.modal({
            backdrop: 'static',
            show: false,
            keyboard: false
        });

        wrapper = $('.wrapper', this.el);
        this.editor = CodeMirror.fromTextArea($('#editor-new', this.el)[0], _.extend(Genghis.defaults.codeMirror, {
            onFocus: function() { wrapper.addClass('focused');    },
            onBlur:  function() { wrapper.removeClass('focused'); }
        }));

        $(window).resize(_.throttle(this.refreshEditor, 100));

        this.modal.bind('hide', this.cancelEdit);
        this.modal.bind('shown', this.refreshEditor);

        this.modal.find('button.cancel').bind('click', this.closeModal);
        this.modal.find('button.save').bind('click', this.saveDocument);

        return this;
    },
    show: function() {
        this.editor.setValue("{\n    \n}\n");
        this.editor.setCursor({line:1, ch:4});
        this.modal
            .css({marginTop: (-10 - (this.el.height() / 2)) + 'px'})
            .modal('show');
    },
    refreshEditor: function() {
        this.editor.refresh();
        this.editor.focus();
    },
    closeModal: function(e) {
        this.modal.modal('hide');
    },
    cancelEdit: function(e) {
        this.editor.setValue('');
    },
    saveDocument: function() {
        var collection = this.collection;
        var closeModal = this.closeModal;

        $.ajax({
            type: 'POST',
            url: Genghis.baseUrl + 'convert-json',
            data: this.editor.getValue(),
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
