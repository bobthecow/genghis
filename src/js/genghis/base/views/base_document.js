Genghis.Views.BaseDocument = Backbone.View.extend({
    errorMarkers: [],
    clearErrors: function() {
        var editor = this.editor;
        this.getErrorBlock().html('');
        _.each(this.errorMarkers, function(marker) {
            editor.clearMarker(marker);
        });
        this.errorMarkers = [];
    },
    getEditorValue: function() {
        this.clearErrors();

        var errorBlock = this.getErrorBlock();
        var editor     = this.editor;
        var markers    = this.errorMarkers;

        try {
            return Genghis.JSON.parse(editor.getValue());
        } catch (e) {
            _.each(e.errors || [e], function(error) {
                var message = error.message;

                if (error.lineNumber && !(/Line \d+/i.test(message))) {
                    message = 'Line ' + error.lineNumber + ': ' + error.message;
                }

                var alertView = new Genghis.Views.Alert({
                    model: new Genghis.Models.Alert({level: 'error', msg: message, block: true})
                });

                errorBlock.append(alertView.render().el);

                if (error.lineNumber) {
                    markers.push(editor.setMarker(error.lineNumber - 1, null, 'line-error'));
                }
            });
        }

        return false;
    }
});
