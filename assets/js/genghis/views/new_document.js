define([
    'jquery', 'underscore', 'backbone', 'genghis/views', 'genghis/views/base_new_document', 'genghis/util',
    'hgn!genghis/templates/new_document', 'bootstrap.modal'
], function($, _, Backbone, Views, BaseNewDocument, Util, template, _1) {

    return Views.NewDocument = BaseNewDocument.extend({
        el:       '#new-document',
        template: template,

        getTextArea: function() {
            return this.$('#editor-new')[0];
        },

        show: function() {
            this.editor.setValue("{\n    \n}\n");
            this.editor.setCursor({line: 1, ch: 4});
            this.modal.modal('show');
        },

        saveDocument: function() {
            var data = this.getEditorValue();
            if (data === false) {
                return;
            }

            var closeModal      = this.closeModal;
            var showServerError = this.showServerError;

            this.collection.create(data, {
                wait: true,

                success: function(doc) {
                    closeModal();
                    app.router.navigate(Util.route(doc.url()), true);
                },

                error: function(doc, xhr) {
                    var msg;
                    try {
                        msg = JSON.parse(xhr.responseText).error;
                    } catch (e) {
                        // do nothing
                    }

                    showServerError(msg || 'Error creating document.');
                }
            });
        }
    });
});
