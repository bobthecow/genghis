define([
    'jquery', 'underscore', 'backbone', 'genghis/views', 'genghis/util', 'genghis/views/confirm',
    'jquery.hoverintent', 'bootstrap.tooltip', 'bootstrap.popover'
], function($, _, Backbone, Views, Util, Confirm, _1, _2) {

    return Views.Row = Backbone.View.extend({
        tagName: 'tr',

        events: {
            'click a.name':         'navigate',
            'click button.destroy': 'destroy'
        },

        initialize: function() {
            _.bindAll(this, 'render', 'navigate', 'remove', 'destroy');

            this.model.bind('change',  this.render);
            this.model.bind('destroy', this.remove);
        },

        render: function() {
            this.$el
                .html(this.template(this.model))
                .toggleClass('error', !!this.model.get('error'))
                .find('.label[title]').tooltip({placement: 'bottom'});
            this.$('.has-details').popover({
                html: true,
                content: function() { return $(this).siblings('.details').html(); },
                title: function() { return $(this).siblings('.details').attr('title'); },
                trigger: 'manual'
            }).hoverIntent(
                function() { $(this).popover('show'); },
                function() { $(this).popover('hide'); }
            );

            return this;
        },

        navigate: function(e) {
            if (e.ctrlKey || e.shiftKey || e.metaKey) return;
            e.preventDefault();
            app.router.navigate(Util.route($(e.target).attr('href')), true);
        },

        remove: function() {
            this.$el.remove();
        },

        isParanoid: false,

        destroy: function() {
            var model = this.model;
            var name  = model.has('name') ? model.get('name') : '';

            if (this.isParanoid) {
                if (!name) {
                    throw 'Unable to confirm destruction without a confirmation string.';
                }

                new Confirm({
                    header: 'Deleting is forever.',
                    body:   'Type <strong>'+name+'</strong> to continue:',
                    confirmInput: name,
                    confirmText:  'Delete '+name+' forever',
                    confirm: function() {
                        model.destroy();
                    }
                });
            } else {
                var options = {
                    confirmText: this.destroyConfirmButton(name),
                    confirm:     function() { model.destroy(); }
                };

                if (this.destroyConfirmText) {
                    options.body = this.destroyConfirmText(name);
                }

                new Confirm(options);
            }
        },

        destroyConfirmButton: function(name) {
            return '<strong>Yes</strong>, delete '+name+' forever';
        }
    });
});
