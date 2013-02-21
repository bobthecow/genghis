Genghis.Views.NewGridFile = Genghis.Views.BaseDocument.extend({
    el: '#new-grid-file',
    template: Genghis.Templates.NewGridFile,
    initialize: function() {
        _.bindAll(
            this, 'render', 'show', 'handleFileInputChange', 'showMetadata', 'refreshEditor', 'closeModal',
            'cancelEdit', 'saveDocument', 'showServerError'
        );

        this.render();
    },
    render: function() {
        var wrapper;

        this.$el = $(this.template.render()).hide().appendTo('body');
        this.el  = this.$el[0];

        this.fileInput = $('<input id="new-grid-file-input" type="file">').hide().appendTo('body');
        this.currentFile = null;

        this.modal = this.$el.modal({
            backdrop: 'static',
            show: false,
            keyboard: false
        });

        wrapper = this.$('.wrapper');
        this.editor = CodeMirror.fromTextArea(this.$('#editor-upload')[0], _.extend({}, Genghis.defaults.codeMirror, {
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

        this.fileInput.bind('change', this.handleFileInputChange);

        return this;
    },
    show: function() {
        // get the file
        this.fileInput.click();
    },
    handleFileInputChange: function(e) {
        this.showMetadata(e.target.files[0]);
    },
    showMetadata: function(file) {
        this.currentFile = file;

        if (file) {
            this.fileInput.val('');

            // now let 'em edit metadata
            this.editor.setValue(Genghis.JSON.stringify({filename: file.name, contentType: file.type || 'binary/octet-stream', metadata: {}}));
            this.editor.setCursor({line: 3, ch: 15});
            this.modal.modal('show');
        }
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
    saveDocument: function() {
        var data = this.getEditorValue();
        if (data === false) {
            return;
        }

        if (data.file) {
            this.showServerError("Unexpected property: 'file'");
            return;
        }

        var closeModal      = this.closeModal;
        var showServerError = this.showServerError;
        var docs            = this.collection;
        var uploadUrl       = this.collection.url.replace('.files/documents', '.files/files');
        var reader          = new FileReader();

        reader.onload = function(e) {
            data.file = e.target.result;

            $.ajax({
                type:        'POST',
                url:         uploadUrl,
                data:        JSON.stringify(data),
                contentType: 'application/json'
            })
                .success(function(doc) {
                    docs.add(doc);
                    closeModal();

                    var id = new Genghis.Models.Document(doc).prettyId();
                    app.router.navigate(Genghis.Util.route(docs.url + '/' + id), true);
                })
                .error(function(xhr) {
                    var msg;
                    try {
                        msg = JSON.parse(xhr.responseText).error;
                    } catch (e) {
                        // do nothing
                    }

                    showServerError(msg || 'Error uploading file.');
                });
        };

        reader.readAsDataURL(this.currentFile);
    }
});
