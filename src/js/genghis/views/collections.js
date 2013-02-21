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
    initialize: function() {
        _.bindAll(this, 'showGridFSAddForm');
        Genghis.Views.BaseSection.prototype.initialize.apply(this, arguments);
    },
    render: function() {
        Genghis.Views.BaseSection.prototype.render.apply(this, arguments);

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

            this.collection.create({name: name + '.files'});
            this.collection.create({name: name + '.chunks'});
        } else {
            this.collection.create({name: name});
        }

        this.closeAddForm();
    },
    showAddForm: function() {
        var wrap = this.$('.input-wrapper');
        if (wrap.length) {
            wrap.replaceWith(wrap.find('input'));
        }

        this.addButton
            .removeClass('add-gridfs')
            .text('Add collection');

        Genghis.Views.BaseSection.prototype.showAddForm.apply(this, arguments);
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
        Genghis.Views.BaseSection.prototype.show.apply(this, arguments);
    },
    hide: function() {
        Mousetrap.unbind('shift+c');
        Genghis.Views.BaseSection.prototype.hide.apply(this, arguments);
    }
});
