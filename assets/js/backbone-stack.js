define(['backbone', 'backbone.declarative', 'backbone.mousetrap'], function(Backbone) {

    // This is ugly, but it'll do for now. Mix in all the Backbone stuff without
    // having to declare 'em all as individual requirements.
  	return Backbone;
});
