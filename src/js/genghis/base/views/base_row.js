Genghis.Views.BaseRow = Backbone.View.extend({
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
        $(this.el)
            .html(this.template.render(this.model))
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
        e.preventDefault();
        app.router.navigate(Genghis.Util.route($(e.target).attr('href')), true);
    },
    remove: function() {
        $(this.el).remove();
    },
    isParanoid: false,
    destroy: function() {
        var model = this.model;
        var name  = model.has('name') ? model.get('name') : '';

        if (this.isParanoid) {
            if (!name) {
                throw 'Unable to confirm destruction without a confirmation string.';
            }

            apprise(
                '<strong>Deleting is forever.</strong><br><br>Type <strong>'+name+'</strong> to continue:',
                {
                    input: true,
                    textOk: 'Delete '+name+' forever'
                },
                function(r) {
                    if (r == name) {
                        model.destroy();
                    } else {
                        apprise('<strong>Phew. That was close.</strong><br><br>'+name+' was not deleted.');
                    }
                }
            );

            _.defer(function() {
                var btn = $('.appriseOuter button[value="ok"]').attr('disabled', true);
                $('.appriseOuter .aTextbox').on('keyup', function() {
                    if ($(this).val() == name) {
                        btn.removeAttr('disabled');
                    } else {
                        btn.attr('disabled', true);
                    }
                });
            });

        } else {
            apprise(
                'Really? There is no undo.',
                {
                    confirm: true,
                    textOk: this.destroyConfirmButton(name)
                },
                function(r) { if (r) model.destroy(); }
            );
        }
    },
    destroyConfirmButton: function(name) {
        return '<strong>Yes</strong>, delete '+name+' forever';
    }
});
