define(function(require) {
    'use strict';

    var $        = require('jquery');
    var _        = require('underscore');
    var View     = require('genghis/views/view');
    var template = require('hgn!genghis/templates/confirm');

    require('bootstrap.modal');

    return View.extend({
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

        initialize: function(options) {
            _.bindAll(this, 'render', 'confirm', 'validateInput', 'dismiss', 'remove');

            this.onConfirm = options.confirm || $.noop;

            this.confirmInput = options.confirmInput;
            this.modalOptions = _.pick(options, 'backdrop', 'keyboard');

            this.options = _.pick(options, 'header', 'body', 'confirmText', 'confirmInput', 'dismissText');

            if (options.show !== false) {
                this.render();
            }
        },

        serialize: function() {
            return _.defaults(this.options, this.defaults);
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
