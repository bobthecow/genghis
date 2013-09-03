define(['backbone-stack', 'genghis/views/view', 'genghis/views', 'hgn!genghis/templates/masthead'], function(Backbone, View, Views, template) {

    return Views.Masthead = View.extend({
        tagName: 'header',
        attributes: {
            'class': 'masthead'
        },
        template: template,

        initialize: function() {
            this.heading = this.options.heading;
            this.content = this.options.content || '';
            this.error   = this.options.error   || false;
            this.epic    = this.options.epic    || false;
            this.sticky  = this.options.sticky  || false;

            this.render();
        },

        serialize: function() {
            return {
                heading: this.heading,
                content: this.content
            };
        },

        afterRender: function() {
            this.$el
                .toggleClass('error',  this.error)
                .toggleClass('epic',   this.epic)
                .toggleClass('sticky', this.sticky)
                .insertAfter('header.navbar');
        }
    });
});
