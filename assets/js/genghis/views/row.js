define([
    'jquery', 'underscore', 'genghis/views/view', 'genghis/views', 'genghis/util', 'genghis/views/confirm',
    'jquery.hoverintent', 'bootstrap.tooltip', 'bootstrap.popover', 'backbone.declarative'
], function($, _, View, Views, Util, Confirm, _1, _2, _3) {

    return Views.Row = View.extend({
        tagName: 'tr',

        events: {
            'click a.name':         'navigate',
            'click button.destroy': 'destroy'
        },

        modelEvents: {
            'change':  'render',
            'destroy': 'remove'
        },

        initialize: function() {
            _.bindAll(this, 'navigate', 'remove', 'destroy');
        },

        afterRender: function() {
            this.$el
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
        },

        navigate: function(e) {
            if (e.ctrlKey || e.shiftKey || e.metaKey) return;
            e.preventDefault();
            app.router.navigate(Util.route($(e.target).attr('href')), true);
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
