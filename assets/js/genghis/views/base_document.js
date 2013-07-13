define([
    'underscore', 'backbone', 'genghis/views', 'genghis/json', 'genghis/views/alert', 'genghis/models/alert'
], function(_, Backbone, Views, GenghisJSON, AlertView, Alert) {
    return Views.BaseDocument = Backbone.View.extend({
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
                        model: new Alert({level: 'error', msg: message, block: true})
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
