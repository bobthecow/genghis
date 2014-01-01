define(function(require) {
    'use strict';

    var $         = require('jquery');
    var Section   = require('genghis/views/section');
    var ServerRow = require('genghis/views/server_row');
    var template  = require('hgn!genghis/templates/servers');

    require('bootstrap.tooltip');

    return Section.extend({
        el:       'section#servers',
        template: template,
        rowView:  ServerRow,

        // override, since the servers section has no model
        // mebbe this model should be the one that holds user config?
        // who knows...
        modelEvents: null,

        afterRender: function() {
            Section.prototype.afterRender.apply(this, arguments);

            // add placeholder help
            $('.help', this.addForm).tooltip({container: 'body'});
        },

        submitAddForm: function() {
            var alerts = this.app.alerts;

            this.collection.create({url: this.$addInput.val()}, {
                wait:    true,
                success: this.closeAddForm,
                error:   function(model, response) {
                    alerts.handleError(response);
                }
            });
        },

        updateTitle: $.noop,

        formatTitle: function() {
            return 'Servers';
        }
    });
});
