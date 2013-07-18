define([
    'underscore', 'mousetrap', 'genghis/views', 'genghis/views/section', 'genghis/views/collection_row',
    'hgn!genghis/templates/collections', 'bootstrap.dropdown'
], function(_, Mousetrap, Views, Section, CollectionRow, template, _1) {

    return Views.Collections = Section.extend({
        el:       'section#collections',
        template: template,
        rowView:  CollectionRow,

        events: {
            'click .add-form button.show':   'showAddForm',
            'click .add-form a.show':        'showAddForm',
            'click .add-form a.show-gridfs': 'showGridFSAddForm',
            'click .add-form button.add':    'submitAddForm',
            'click .add-form button.cancel': 'closeAddForm',
            'keyup .add-form input.name':    'updateOnKeyup'
        },

        initialize: function() {
            _.bindAll(this, 'showGridFSAddForm');
            Section.prototype.initialize.apply(this, arguments);
        },

        render: function() {
            Section.prototype.render.apply(this, arguments);

            // Yay dropdowns!
            this.$('.dropdown-toggle').dropdown();

            return this;
        },

        formatTitle: function(model) {
            return model.id ? (model.id + ' Collections') : 'Collections';
        },

        submitAddForm: function() {
            var name = this.addInput.val().replace(/^\s+/, '').replace(/\s+$/, '');
            if (name === '') {
                window.app.alerts.add({msg: 'Please enter a valid collection name.'});
                return;
            }

            if (this.addButton.hasClass('add-gridfs')) {
                name = name.replace(/\.(files|chunks)$/, '');

                var closeAfterTwo = _.after(2, this.closeAddForm);

                this.collection.create({name: name + '.files'}, {
                    wait:    true,
                    success: closeAfterTwo,
                    error:   function(model, response) {
                        window.app.alerts.handleError(response);
                    }
                });

                this.collection.create({name: name + '.chunks'}, {
                    wait:    true,
                    success: closeAfterTwo,
                    error:   function(model, response) {
                        window.app.alerts.handleError(response);
                    }
                });
            } else {
                this.collection.create({name: name}, {
                    wait:    true,
                    success: this.closeAddForm,
                    error:   function(model, response) {
                        window.app.alerts.handleError(response);
                    }
                });
            }
        },

        showAddForm: function() {
            var wrap = this.$('.input-wrapper');
            if (wrap.length) {
                wrap.replaceWith(wrap.find('input'));
            }

            this.addButton
                .removeClass('add-gridfs')
                .text('Add collection');

            Section.prototype.showAddForm.apply(this, arguments);
        },

        showGridFSAddForm: function(e) {
            if (e && e.preventDefault) {
                e.preventDefault();
            }

            if (this.$('.input-wrapper').length === 0) {
                this.addInput.wrap('<div class="input-wrapper input-append">');
                $('<span class="add-on">.files</span>').insertAfter(this.addInput);
            }

            this.addButton
                .addClass('add-gridfs')
                .text('Add GridFS collection');

            this.addForm.removeClass('inactive');

            if (this.addInput.val() === '') {
                this.addInput.val('fs');
            }

            this.addInput.select().focus();
        },

        show: function() {
            Mousetrap.bind('shift+c', this.showGridFSAddForm);
            Section.prototype.show.apply(this, arguments);
        },

        hide: function() {
            Mousetrap.unbind('shift+c');
            Section.prototype.hide.apply(this, arguments);
        }
    });
});
