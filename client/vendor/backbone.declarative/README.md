# Backbone.declarative

A Backbone plugin that adds declarative model and collection event binding to Backbone Views.

## Running the tests

    git submodule update --init --recursive
    open test/index.html

## Usage

When extending a view just specify your declarative `modelEvents` and `collectionEvents`.  

Example:

```javascript
var Section = Backbone.View.extend({
  collectionEvents: {
    'add': 'addNewExercise'
  , 'remove': 'removeExercise'
  }

  modelEvents: {
    'change:programming_language': 'onProgLangChange'
  }
  ...
});
```

The events will automatically be cleaned up when the view's `remove` or
`stopListening` methods are called.

## Usage in Todos example

The following is part of the TodoView class definition from the famous [Todos Example](http://backbonejs.org/docs/todos.html).  
```javascript
var TodoView = Backbone.View.extend({
  template: _.template($('#item-template').html()),

  events: {
    "click .toggle"   : "toggleDone",
    "dblclick .view"  : "edit",
    "click a.destroy" : "clear",
    "keypress .edit"  : "updateOnEnter",
    "blur .edit"      : "close"
  },

  initialize: function() {
    this.listenTo(this.model, 'change', this.render);
    this.listenTo(this.model, 'destroy', this.remove);
  },
  ...
```


Using Backbone.declarative it becomes:
```javascript
var TodoView = Backbone.View.extend({
  template: _.template($('#item-template').html()),

  events: {
    "click .toggle"   : "toggleDone",
    "dblclick .view"  : "edit",
    "click a.destroy" : "clear",
    "keypress .edit"  : "updateOnEnter",
    "blur .edit"      : "close"
  },

  modelEvents: {
    'change': 'render'
  , 'destroy': 'remove'
  }
  ...
```

## API

#### bindModelEvents

Takes an event hash `modelEvents` with keys being the model event names to bind on and values being  
functions or strings representing method names. (Also used internally for the declarative format).

### unbindModelEvents

Removes all event handlers attached by the `bindModelEvents`.

#### bindCollectionEvents

Same as `bindModelEvents` but for collections.

### unbindCollectionEvents

Same as `bindModelEvents` but for collections.


## License
MIT License.  
Copyright (c) 2012 Amjad Masad <amjad@codecademy.com> Ryzac, Inc.

Contributors: [philfreo](https://github.com/philfreo)
