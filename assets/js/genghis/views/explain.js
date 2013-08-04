define([
    'underscore', 'backbone', 'genghis/views/view', 'genghis/views', 'genghis/util', 'hgn!genghis/templates/explain'
], function(_, Backbone, View, Views, Util, template) {

    return Views.Explain = View.extend({
        el:       'section#explain',
        template: template,

        initialize: function() {
            _.bindAll(this, 'render');
            this.model.bind('sync', this.updateExplain, this);
            this.render();
        },

        render: function() {
            this.$el.html(this.template({}));
            Util.attachCollapsers(this.$('article')[0]);
            return this;
        },

        updateExplain: function() {
            this.$('.document').html(this.model.prettyPrint());
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
