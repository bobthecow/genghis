define([
    'jquery', 'underscore', 'genghis/views', 'genghis/views/base_document', 'codemirror',
    'genghis/util', 'genghis/views/alert', 'genghis/models/alert', 'genghis/defaults',
    'hgn!genghis/templates/new_document', 'bootstrap.modal', 'codemirror.matchbrackets',
    'codemirror.javascript'
], function($, _, Views, BaseDocument, CodeMirror, Util, AlertView, Alert, defaults, template, _1, _2, _3, _4) {

    return Views.NewDocument = BaseDocument.extend({
        el:       '#new-document',
        template: template,

        initialize: function() {
            _.bindAll(
                this, 'render', 'getTextArea', 'show', 'refreshEditor', 'closeModal',
                'cancelEdit', 'saveDocument', 'showServerError'
            );
            this.render();
        },

        render: function() {

            // TODO: clean this up, it's weird.
            this.$el   = $(this.template()).hide().appendTo('body');
            this.el    = this.$el[0];
            this.modal = this.$el.modal({
                backdrop: 'static',
                show:     false,
                keyboard: false
            });

            var wrapper = this.$('.wrapper');
            this.editor = CodeMirror.fromTextArea(this.getTextArea(), _.extend({}, defaults.codeMirror, {
                extraKeys: {
                     'Ctrl-Enter': this.saveDocument,
                     'Cmd-Enter':  this.saveDocument
                 }
            }));

            this.editor.on('focus', function() { wrapper.addClass('focused');    });
            this.editor.on('blur',  function() { wrapper.removeClass('focused'); });

            $(window).resize(_.throttle(this.refreshEditor, 100));

            this.modal.on('hide.bs.modal', this.cancelEdit);
            this.modal.on('shown.bs.modal', this.refreshEditor);

            this.modal.find('button.cancel').bind('click', this.closeModal);
            this.modal.find('button.save').bind('click', this.saveDocument);

            return this;
        },

        cancelEdit: function(e) {
            this.editor.setValue('');
        },

        refreshEditor: function() {
            this.editor.refresh();
            this.editor.focus();
        },

        getErrorBlock: function() {
            var errorBlock = this.$('div.errors');
            if (errorBlock.length === 0) {
                errorBlock = $('<div class="errors"></div>').prependTo(this.$('.modal-body'));
            }

            return errorBlock;
        },

        showServerError: function(message) {
            var alertView = new AlertView({
                model: new Alert({level: 'danger', msg: message, block: true})
            });

            this.getErrorBlock().append(alertView.render().el);
        },

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
        },

        closeModal: function(e) {
            this.modal.modal('hide');
        }

    });
});
