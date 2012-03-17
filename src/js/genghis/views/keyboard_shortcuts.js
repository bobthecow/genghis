Genghis.Views.KeyboardShortcuts = Backbone.View.extend({
    tagName:  'div',
    template: _.template($('#keyboard-shortcuts-template').html()),
    events: {
        'click a.close': 'hide'
    },
    initialize: function() {
        _.bindAll(this, 'render', 'show', 'hide', 'toggle');
        $(document).bind('keyup', 'shift+/', this.toggle);
        this.render();
    },
    render: function() {
        $(this.el).html(this.template()).modal({backdrop: true, keyboard: true, show: false});
        return this;
    },
    show: function() {
        $(this.el).modal('show');
    },
    hide: function() {
        $(this.el).modal('hide');
    },
    toggle: function() {
        $(this.el).modal('toggle');
    }
});
