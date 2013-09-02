define(['backbone.giraffe', 'genghis/models'], function(Giraffe, Models) {

    return Models.Alert = Giraffe.Model.extend({
        defaults: {
            level: 'warning',
            block: false
        },

        block: function() {
            return !!this.get('block');
        },

        level: function() {
            var level = this.get('level');

            return (level === 'error') ? 'danger' : level;
        },

        msg: function() {
            return this.get('msg');
        }
    });
});
