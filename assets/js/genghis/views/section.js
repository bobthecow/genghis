define([
    'jquery', 'underscore', 'backbone-stack', 'genghis/views/view', 'genghis/views', 'jquery.tablesorter',
    'tablesorter-size-parser'
], function($, _, Backbone, View, Views, _1, _2) {

    return Views.Section = View.extend({

        ui: {
            '$title':         '> header h2',
            '$table':         'table',
            '$tbody':         'table tbody',
            '$addForm':       '.add-form',
            '$addInput':      '.add-form input',
            '$addFormToggle': '.add-form-toggle'
        },

        events: {
            'click .add-form-toggle button': 'showAddForm',
            'click .add-form button.add':    'submitAddForm',
            'click .add-form button.cancel': 'closeAddForm',
            'keyup .add-form input.name':    'updateOnKeyup'
        },

        keyboardEvents: {
            'c': 'showAddForm'
        },

        modelEvents: {
            'change': 'updateTitle',
        },

        collectionEvents: {
            'reset':   'render',
            'add':     'addModelAndUpdate',
            'request': 'startSpinning',
            'sync':    'stopSpinning',
            'destroy': 'stopSpinning'
        },

        initialize: function() {
            _.bindAll(
                this, 'render', 'updateTitle', 'showAddForm', 'submitAddForm',
                'closeAddForm', 'updateOnKeyup', 'addModel', 'addModelAndUpdate',
                'addAll', 'show', 'hide', 'startSpinning', 'stopSpinning'
            );

            this.render();
        },

        serialize: function() {
            return {title: this.formatTitle(this.model)};
        },

        afterRender: function() {
            this.addAll();

            // Sort this bad boy.
            this.$table.tablesorter({textExtraction: function(el) {
                return $('.value', el).text() || $(el).text();
            }});

            if (this.collection.size()) {
                this.$table.trigger('sorton', [[[0,0]]]);
            }
        },

        updateTitle: function() {
            this.$title.text(this.formatTitle(this.model));
        },

        showAddForm: function(e) {
            if (e && e.preventDefault()) {
                e.preventDefault();
            }

            this.$addFormToggle.hide();
            this.$addForm.show();
            this.$addInput.select().focus();
        },

        submitAddForm: function() {
            var alerts = this.app.alerts;

            this.collection.create({name: this.$addInput.val()}, {
                wait:    true,
                success: this.closeAddForm,
                error:   function(model, response) {
                    alerts.handleError(response);
                }
            });
        },

        closeAddForm: function() {
            this.$addFormToggle.show();
            this.$addForm.hide();
            this.$addInput.val('');
        },

        updateOnKeyup: function(e) {
            if (e.keyCode == 13) this.submitAddForm();  // enter
            if (e.keyCode == 27) this.closeAddForm();   // escape
        },

        addModel: function(model) {
            var view = new this.rowView({model: model});
            this.$tbody.append(view.render().el);
        },

        addModelAndUpdate: function(model) {
            this.addModel(model);
            this.$table.trigger('update');
        },

        addAll: function() {
            this.$tbody.html('');
            this.collection.each(this.addModel);
        },

        show: function() {
            this.bindKeyboardEvents();
            $('body').addClass('section-' + this.$el.attr('id'));
            this.$el.show();
            $(document).scrollTop(0);
        },

        hide: function() {
            this.unbindKeyboardEvents();
            $('body').removeClass('section-' + this.$el.attr('id'));
            this.$el.hide();
        },

        startSpinning: function() {
            this.$el.addClass('spinning');
        },

        stopSpinning: function() {
            this.$el.removeClass('spinning');
        }
    });
});
