define(function(require) {
    'use strict';

    var _       = require('underscore');
    var Giraffe = require('backbone.giraffe');
    var Alert   = require('genghis/models/alert');

    return Giraffe.Collection.extend({
        model: Alert,

        initialize: function() {
            _.bindAll(this, 'handleError');
        },

        handleError: function(response) {
            if (response.readyState === 0) return;

            try {
                data = JSON.parse(response.responseText);
            } catch (e) {
                data = {error: response.responseText};
            }
            msg = data.error || '<strong>FAIL</strong> An unexpected server error has occurred.';
            this.add({level: 'danger', msg: msg, block: !msg.search(/<(p|ul|ol|div)[ >]/)});
        }
    });
});
