window.Genghis = {
    Base:        {},
    Models:      {},
    Collections: {},
    Views:       {},
    boot: function(baseUrl) {
        baseUrl = baseUrl + (baseUrl.charAt(baseUrl.length - 1) == '/' ? '' : '/');
        window.App = new Genghis.Views.App({base_url: baseUrl});
        Backbone.history.start({pushState: true, root: baseUrl});
    }
};
