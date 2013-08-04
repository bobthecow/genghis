define([
    'underscore', 'genghis/views/view', 'genghis/views', 'genghis/json',
    'genghis/views/alert', 'genghis/models/alert'
], function(_, View, Views, GenghisJSON, AlertView, Alert) {

    // TODO: this shouldn't be BaseDocument, it should be a DocumentEditor view
    // that's used by both Document and NewDocument views to edit document JSON.
    return Views.BaseDocument = View.extend({
        errorLines: [],

        clearErrors: function() {
            var editor = this.editor;
            this.getErrorBlock().html('');
            _.each(this.errorLines, function(marker) {
                editor.removeLineClass(marker, 'background', 'error-line');
            });
            this.errorLines = [];
        },

        getEditorValue: function() {
            this.clearErrors();

            var errorBlock = this.getErrorBlock();
            var editor     = this.editor;
            var errorLines = this.errorLines;

            try {
                return GenghisJSON.parse(editor.getValue());
            } catch (e) {
                _.each(e.errors || [e], function(error) {
                    var message = error.message;

                    if (error.lineNumber && !(/Line \d+/i.test(message))) {
                        message = 'Line ' + error.lineNumber + ': ' + error.message;
                    }

                    var alertView = new AlertView({
                        model: new Alert({level: 'danger', msg: message, block: true})
                    });

                    errorBlock.append(alertView.render().el);

                    if (error.lineNumber) {
                        errorLines.push(editor.addLineClass(error.lineNumber - 1, 'background', 'error-line'));
                    }
                });
            }

            return false;
        }
    });
});
