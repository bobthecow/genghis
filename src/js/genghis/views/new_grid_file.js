Genghis.Views.NewGridFile = Genghis.Views.BaseNewDocument.extend({
    el: '#new-grid-file',
    template: Genghis.Templates.NewGridFile,
    initialize: function() {
        _.bindAll(this, 'handleFileInputChange', 'showMetadata');
        Genghis.Views.BaseNewDocument.prototype.initialize.apply(this, arguments);
    },
    render: function() {
        Genghis.Views.BaseNewDocument.prototype.render.apply(this, arguments);

        this.fileInput = $('<input id="new-grid-file-input" type="file">').hide().appendTo('body');
        this.currentFile = null;

        this.fileInput.bind('change', this.handleFileInputChange);

        return this;
    },
    getTextArea: function() {
        return this.$('#editor-upload')[0];
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
