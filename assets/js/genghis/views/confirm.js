define([
    'jquery', 'underscore', 'backbone-stack', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/confirm', 'bootstrap.modal'
], function($, _, Backbone, View, Views, template, _1) {

    return Views.Confirm = View.extend({
        className: 'modal confirm-modal',
        template: template,

        ui: {
            '$confirm': 'button.confirm'
        },

        events: {
            'click $confirm':       'confirm',
            'click button.dismiss': 'dismiss',
            'keyup .confirm-input': 'validateInput'
        },

        defaults: {
            header:      null,
            body:        'Really? There is no undo.',
            confirmText: 'Okay',
            dismissText: 'Cancel'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'confirm', 'validateInput', 'dismiss', 'remove');

            this.onConfirm = this.options.confirm || function() {};

            this.confirmInput = this.options.confirmInput;
            this.modalOptions = _.pick(this.options, 'backdrop', 'keyboard');

            if (this.options.show !== false) {
                this.render();
            }
        },

        serialize: function() {
            return _.defaults(
                _.pick(this.options, 'header', 'body', 'confirmText', 'confirmInput', 'dismissText'),
                this.defaults
            );
        },

        afterRender: function() {
            var $el = this.$el;

            if (this.confirmInput) {
                $el.on('shown.bs.modal', function() {
                    $el.find('.confirm-input').focus();
                });
            }

            $el.modal(this.modalOptions);
        },

        confirm: function() {
            this.onConfirm();
            this.dismiss();
        },

        validateInput: function(e) {
            if ($(e.target).val() == this.confirmInput) {
                this.$confirm.removeAttr('disabled');

                // handle enter
                if (e.keyCode == 13) {
                    e.preventDefault();
                    this.$confirm.click();
                }
            } else {
                this.$confirm.attr('disabled', true);
            }
        },

        dismiss: function() {
            this.$el.on('hidden.bs.modal', this.remove).modal('hide');
        }
    });
});
