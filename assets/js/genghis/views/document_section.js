define([
    'jquery', 'underscore', 'backbone', 'genghis/views/view', 'genghis/views', 'genghis/views/document', 'hgn!genghis/templates/document_section'
], function($, _, Backbone, View, Views, DocumentView, template) {

    return Views.DocumentSection = View.extend({
        el:       'section#document',
        template: template,

        ui: {
            '$content': '.content'
        },

        initialize: function() {
            this.listenTo(this.model, {
                'change': this.render
            });
        },

        afterRender: function() {
            this.$el.removeClass('spinning');
            var view = new DocumentView({model: this.model});
            this.$content.html(view.render().el);
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
