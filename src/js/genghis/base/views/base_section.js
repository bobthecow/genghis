Genghis.Views.BaseSection = Backbone.View.extend({
    events: {
        'click .add-form button.show':   'showAddForm',
        'click .add-form button.add':    'submitAddForm',
        'click .add-form button.cancel': 'closeAddForm',
        'keyup .add-form input.name':    'updateOnKeyup'
    },
    initialize: function() {
        _.bindAll(
            this, 'render', 'updateTitle', 'showAddForm', 'showAddFormIfVisible',
            'submitAddForm', 'closeAddForm', 'updateOnKeyup', 'addModel',
            'addModelAndUpdate', 'addAll'
        );

        if (this.model) {
            this.model.bind('change', this.updateTitle);
        }

        if (this.collection) {
            this.collection.bind('reset', this.render);
            this.collection.bind('add',   this.addModelAndUpdate);
        }

        $(document).bind('keyup', 'c', this.showAddFormIfVisible);

        this.render();
    },
    render: function() {
        $(this.el).html(this.template.render({title: this.formatTitle(this.model)}));

        this.addForm      = this.$('.add-form');
        this.addButton    = this.$('.add-form button.add');
        this.addInput     = this.$('.add-form input');
        this.cancelButton = this.$('.add-form button.cancel');

        this.addAll();

        // add placeholder help
        this.$('.help', this.addForm).tooltip();

        // don't sort the actions column
        var headerConfig = {};
        headerConfig[this.$('table thead th').length - 1] = {sorter: false};

        // do sort everything else
        this.$('table').tablesorter({headers: headerConfig, textExtraction: function(el) {
            return $('.value', el).text() || $(el).text();
        }});
        if (this.collection.size()) this.$('table').trigger('sorton', [[[0,0]]]);

        return this;
    },
    updateTitle: function() {
        this.$('> header h2').text(this.formatTitle(this.model));
    },
    showAddForm: function() {
        this.addForm.removeClass('inactive');
        this.addInput.focus();
    },
    showAddFormIfVisible: function(e) {
        if ($(this.el).is(':visible')) {
            e.preventDefault();
            this.showAddForm();
        }
    },
    submitAddForm: function() {
        this.collection.create({name: this.addInput.val()});
        this.closeAddForm();
    },
    closeAddForm: function() {
        this.addForm.addClass('inactive');
        this.addInput.val('');
    },
    updateOnKeyup: function(e) {
        if (e.keyCode == 13) this.submitAddForm();  // enter
        if (e.keyCode == 27) this.closeAddForm();   // escape
    },
    addModel: function(model) {
        var view = new this.rowView({model: model});
        this.$('table tbody').append(view.render().el);
    },
    addModelAndUpdate: function(model) {
        this.addModel(model);
        this.$('table').trigger('update');
    },
    addAll: function() {
        this.$('table tbody').html('');
        this.collection.each(this.addModel);

        $(this.el).removeClass('spinning');
    }
});
