define(['jquery', 'backbone', 'genghis', 'genghis/views/app'], function($, Backbone, Genghis, AppView) {
    return Genghis.boot = function(baseUrl) {
        $(function() {
            baseUrl = baseUrl + (baseUrl.charAt(baseUrl.length - 1) == '/' ? '' : '/');
            window.app = new AppView({baseUrl: baseUrl});
            Backbone.history.start({pushState: true, root: baseUrl});
        });
    };
});
