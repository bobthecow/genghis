Genghis.Views.Document = Backbone.View.extend({
    el: 'section#document',
    template: Genghis.Templates.Document,
    initialize: function() {
        _.bindAll(this, 'render');
        this.model.bind('change', this.render);
    },
    render: function() {
        var view = new Genghis.Views.DocumentView({model: this.model});
        this.$el.removeClass('spinning').html(this.template.render({model: this.model}));
        this.$('.content').html(view.render().el);
        return this;
    },
    show: function() {
        $('body').addClass('section-' + this.$el.attr('id'));
        this.$el.addClass('spinning').show();
        $(document).scrollTop(0);
    },
    hide: function() {
        $('body').removeClass('section-' + this.$el.attr('id'));
        this.$el.hide();
    }
});
