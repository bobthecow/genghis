Genghis.Views.Collections = Genghis.Views.BaseSection.extend({
    el: 'section#collections',
    template: Genghis.Templates.Collections,
    rowView: Genghis.Views.CollectionRow,
    events: {
        'click .add-form button.show':   'showAddForm',
        'click .add-form a.show':        'showAddForm',
        'click .add-form a.show-gridfs': 'showGridFSAddForm',
        'click .add-form button.add':    'submitAddForm',
        'click .add-form button.cancel': 'closeAddForm',
        'keyup .add-form input.name':    'updateOnKeyup'
    },
    formatTitle: function(model) {
        return model.id ? (model.id + ' Collections') : 'Collections';
    },
    submitAddForm: function() {
        var name = this.addInput.val().replace(/^\s+/, '').replace(/\s+$/, '');
        if (name === '') {
            window.app.alerts.add({msg: 'Please enter a valid collection name.'});
        }

        if (this.addButton.hasClass('add-gridfs')) {
            name = name.replace(/\.(files|chunks)$/, '');

            this.collection.create({name: name + '.files'});
            this.collection.create({name: name + '.chunks'});
        } else {
            this.collection.create({name: name});
        }

        this.closeAddForm();
    },
    showGridFSAddForm: function() {
        this.addInput.wrap('<div class="input-wrapper input-append">');
        $('<span class="add-on">.files</span>').insertAfter(this.addInput);

        this.addButton
            .addClass('add-gridfs')
            .text('Add GridFS collection');

        this.addForm.removeClass('inactive');

        this.addInput
            .val('fs')
            .select()
            .focus();
    },
    closeAddForm: function() {
        var wrap = this.$('.input-wrapper');
        if (wrap.length) {
            wrap.replaceWith(wrap.find('input'));
        }

        this.addButton
            .removeClass('add-gridfs')
            .text('Add collection');

        this.addForm.addClass('inactive');
        this.addInput.val('');
    }
});
