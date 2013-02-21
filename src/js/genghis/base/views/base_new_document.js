Genghis.Views.BaseNewDocument = Genghis.Views.BaseDocument.extend({
    initialize: function() {
        _.bindAll(
            this, 'render', 'getTextArea', 'show', 'refreshEditor', 'closeModal',
            'cancelEdit', 'saveDocument', 'showServerError'
        );
        this.render();
    },
    render: function() {
        this.$el   = $(this.template.render()).hide().appendTo('body');
        this.el    = this.$el[0];
        this.modal = this.$el.modal({
            backdrop: 'static',
            show:     false,
            keyboard: false
        });

        var wrapper = this.$('.wrapper');
        this.editor = CodeMirror.fromTextArea(this.getTextArea(), _.extend({}, Genghis.defaults.codeMirror, {
            onFocus: function() { wrapper.addClass('focused');    },
            onBlur:  function() { wrapper.removeClass('focused'); },
            extraKeys: {
                 'Ctrl-Enter': this.saveDocument,
                 'Cmd-Enter':  this.saveDocument
             }
        }));

        $(window).resize(_.throttle(this.refreshEditor, 100));

        this.modal.bind('hide', this.cancelEdit);
        this.modal.bind('shown', this.refreshEditor);

        this.modal.find('button.cancel').bind('click', this.closeModal);
        this.modal.find('button.save').bind('click', this.saveDocument);

        return this;
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
    getErrorBlock: function() {
        var errorBlock = this.$('div.errors');
        if (errorBlock.length === 0) {
            errorBlock = $('<div class="errors"></div>').prependTo(this.$('.modal-body'));
        }

        return errorBlock;
    },
    showServerError: function(message) {
        var alertView = new Genghis.Views.Alert({
            model: new Genghis.Models.Alert({level: 'error', msg: message, block: true})
        });

        this.getErrorBlock().append(alertView.render().el);
    },
});
