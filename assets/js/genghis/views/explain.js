define([
    'underscore', 'backbone', 'genghis/views/view', 'genghis/views', 'genghis/util', 'hgn!genghis/templates/explain'
], function(_, Backbone, View, Views, Util, template) {

    return Views.Explain = View.extend({
        el:       'section#explain',
        template: template,

        ui: {
            '$doc': '.document'
        },

        initialize: function() {
            this.listenTo(this.model, {
                'sync': this.updateExplain
            });

            this.render();
        },

        afterRender: function() {
            Util.attachCollapsers(this.$('article')[0]);
        },

        updateExplain: function() {
            this.$doc.html(this.model.prettyPrint());
            this.$el.removeClass('spinning');
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
