define(['genghis/views', 'backbone.giraffe'], function(Views, Giraffe) {

    // Let's use a base class!
    return Views.View = Giraffe.View.extend({
        templateStrategy: 'jst'
    });
});
