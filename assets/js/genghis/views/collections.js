define([
    'underscore', 'mousetrap', 'genghis/views', 'genghis/views/section', 'genghis/views/collection_row',
    'hgn!genghis/templates/collections', 'bootstrap.dropdown'
], function(_, Mousetrap, Views, Section, CollectionRow, template, _1) {

    return Views.Collections = Section.extend({
        el:       'section#collections',
        template: template,
        rowView:  CollectionRow,

        events: _.extend({
            'click .add-form-toggle a.show':        'showAddForm',
            'click .add-form-toggle a.show-gridfs': 'showAddFormGridFs',
            'click .add-form-gridfs button.add':    'submitAddFormGridFs',
            'click .add-form-gridfs button.cancel': 'closeAddFormGridFs',
            'keyup .add-form-gridfs input.name':    'updateOnKeyupGridFs'
        }, Section.prototype.events),

        initialize: function() {
            _.bindAll(this, 'showAddFormGridFs', 'submitAddFormGridFs', 'closeAddFormGridFs', 'updateOnKeyupGridFs');
            Section.prototype.initialize.apply(this, arguments);
        },

        render: function() {
            Section.prototype.render.apply(this, arguments);

            // TODO: remove this once we switch to using default render :)
            this.$addFormGridFs  = this.$('.add-form-gridfs');
            this.$addInputGridFs = this.$('.add-input-gridfs');
            this.$addFormToggle  = this.$('.add-form-toggle');

            // Yay dropdowns!
            this.$('.dropdown-toggle').dropdown();

            return this;
        },

        formatTitle: function(model) {
            return model.id ? (model.id + ' Collections') : 'Collections';
        },

        showAddFormGridFs: function(e) {
            if (e && e.preventDefault()) {
                e.preventDefault();
            }

            this.$addFormToggle.hide();
            this.$addFormGridFs.show();
            this.$addInputGridFs.select().focus();
        },

        submitAddFormGridFs: function() {
            var alerts = this.app.alerts;
            var name   = this.$addInputGridFs.val().replace(/^\s+/, '').replace(/\s+$/, '');
            if (name === '') {
                alerts.add({msg: 'Please enter a valid collection name.'});
                return;
            }

            name = name.replace(/\.(files|chunks)$/, '');

            var closeAfterTwo = _.after(2, this.closeAddFormGridFs);

            this.collection.create({name: name + '.files'}, {
                wait:    true,
                success: closeAfterTwo,
                error:   function(model, response) {
                    alerts.handleError(response);
                }
            });

            this.collection.create({name: name + '.chunks'}, {
                wait:    true,
                success: closeAfterTwo,
                error:   function(model, response) {
                    alerts.handleError(response);
                }
            });
        },

        closeAddFormGridFs: function() {
            this.$addFormToggle.show();
            this.$addFormGridFs.hide();
            this.$addInputGridFs.val('');
        },

        updateOnKeyupGridFs: function(e) {
            if (e.keyCode == 13) this.submitAddFormGridFs();  // enter
            if (e.keyCode == 27) this.closeAddFormGridFs();   // escape
        },

        show: function() {
            Mousetrap.bind('shift+c', this.showAddFormGridFs);
            Section.prototype.show.apply(this, arguments);
        },

        hide: function() {
            Mousetrap.unbind('shift+c');
            Section.prototype.hide.apply(this, arguments);
        }
    });
});
