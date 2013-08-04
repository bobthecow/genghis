define([
    'jquery', 'underscore', 'backbone', 'genghis/views/view', 'genghis/views', 'genghis/views/document', 'hgn!genghis/templates/document_section'
], function($, _, Backbone, View, Views, DocumentView, template) {

    return Views.DocumentSection = View.extend({
        el:       'section#document',
        template: template,

        initialize: function() {
            _.bindAll(this, 'render');
            this.model.bind('change', this.render);
        },

        render: function() {
            var view = new DocumentView({model: this.model});
            this.$el.removeClass('spinning').html(this.template({model: this.model}));
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
});
