Genghis.Views.NewDocument = Backbone.View.extend({
    el: '#new-document',
    template: Genghis.Templates.NewDocument,
    initialize: function() {
        _.bindAll(this, 'render', 'show', 'resizeEditor', 'closeModal', 'cancelEdit', 'saveDocument');
        this.render();
    },
    render: function() {
        this.el = $(this.template.render()).hide().appendTo('body');

        this.modal = this.el.modal({
            backdrop: 'static',
            show: false,
            keyboard: false
        });

        this.modal.bind('hide', this.cancelEdit);

        var wrapper = $('.wrapper', this.el);
        this.editor = CodeMirror.fromTextArea($('#editor-new', this.el)[0], {
            mode: "application/json",
            lineNumbers: true,
            tabSize: 2,
            indentUnit: 2,
            onFocus: function() { wrapper.addClass('focused');    },
            onBlur:  function() { wrapper.removeClass('focused'); }
        });

        $(window).resize(_.throttle(this.resizeEditor, 100));

        this.modal.bind('shown', this.resizeEditor);
        this.modal.find('button.cancel').bind('click', this.closeModal);
        this.modal.find('button.save').bind('click', this.saveDocument);

        window.GenghisEditor = this.editor;

        return this;
    },
    show: function() {
        this.el.find('#editor-new').height($(window).height() - 250);
        this.editor.setValue("{\n  \n}\n");
        this.editor.setCursor({line:1, ch:2});
        this.modal.css({marginTop: (30 - (this.el.height() / 2)) + 'px'}).modal('show');
        setTimeout(this.editor.focus, 50);
    },
    resizeEditor: function() {
        this.editor.refresh();
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
