Genghis.Views.NavSection = Backbone.View.extend({
    template: _.template($('#nav-section-template').html()),
    menuTemplate: _.template($('#nav-section-menu-template').html()),
    initialize: function() {
        _.bindAll(this, 'render');

        this.model.bind('change',     this.updateLink, this);
        this.collection.bind('reset', this.renderMenu, this);

        this.render();
    },
    render: function() {
        $(this.el).html(this.template({model: this.model}));

        this.$('.dropdown-toggle').hoverIntent(function(e) {
            $(e.target)
                .parent('li').addClass('open')
                    .siblings('li').removeClass('open');
        }, $.noop);

        return this;
    },
    updateLink: function() {
        this.$('a.dropdown-toggle').text(this.model.id ? this.model.id : '').attr('href', this.model.id ? this.model.url : '');
    },
    renderMenu: function() {
        this.$('ul.menu-dropdown').html(this.menuTemplate({model: this.model, collection: this.collection}));
    }
});
