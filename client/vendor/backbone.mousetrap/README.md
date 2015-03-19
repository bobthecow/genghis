backbone.mousetrap
==================

Bring [Backbone.js](http://backbonejs.org/) and [Mousetrap](https://github.com/ccampbell/mousetrap) together nicely for declarative keyboard event bindings on Backbone views.

* Nice declarative syntax
* Allows you to bind different keyboard events to different views
* Keyboard events are unbound automatically when the view's `remove()` is called


```
var View = Backbone.View.extend({
    keyboardEvents: {
        'command+shift+t': 'test',
        'control+shift+t': 'test'
    },

    test: function(ev) {
        alert('hello world!');
    }
});
```

MIT LICENSE

---

Thanks to our friends at Codecademy for showing us the declarative light with [backbone.declarative](https://github.com/Codecademy/backbone.declarative).