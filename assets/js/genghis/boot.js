define(function(require) {
    'use strict';

    var $        = require('jquery');
    var Backbone = require('backbone-stack');
    var AppView  = require('genghis/views/app');

    return function(baseUrl) {
        $(function() {
            baseUrl = baseUrl + (baseUrl.charAt(baseUrl.length - 1) == '/' ? '' : '/');
            window.app = new AppView({baseUrl: baseUrl});
            Backbone.history.start({pushState: true, root: baseUrl});
        });
    };
});
