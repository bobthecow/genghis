(function() {
  var Contrib,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  if (typeof Giraffe === 'undefined') {
    throw new Error('Can\'t find Giraffe');
  }

  Contrib = Giraffe.Contrib = {
    version: '0.2.1'
  };

  /*
  * A __Controller__ is a simple evented class that can participate in appEvents.
  * It demonstrates the usage of `Giraffe.configure` which extends any function
  * instance with [features including lifecycle management, app events, and more.]
  * (http://barc.github.io/backbone.giraffe/backbone.giraffe.html#configure)
  *
  * @param {Object} options
  *
  * - all options get merged into object like models and views.
  *
  * @example
  *
  *  var SfxController = Giraffe.Contrib.Controller.extend({
  *    appEvents: {
  *      'process:complete': 'playDingSound'
  *    },
  *
  *    playDingSound: function() {
  *      // Code for playing sound...
  *    }
  *  });
  *
  *  // Options get merged into object like views and models.
  *  var sfxController = new SfxController({
  *    basePath: 'media/audio',
  *  });
  *
  * @author darthapo <github.com/darthapo>
  */


  Contrib.Controller = (function() {
    _.extend(Controller.prototype, Backbone.Events);

    function Controller(options) {
      Giraffe.configure(this, options);
    }

    return Controller;

  })();

  /*
  * `Backbone.Giraffe.Contrib` is a collection of officially supported classes that are
  * built on top of `Backbone.Giraffe`. These classes should be considered
  * experimental as their APIs are subject to undocumented changes.
  */


  /*
  * A __CollectionView__ mirrors a `Collection`, rendering a view for each model.
  *
  * @param {Object} options
  *
  * - [collection] - {Collection} The collection instance for the `CollectionView`. Defaults to a new __Giraffe.Collection__.
  * - [modelView] - {ViewClass} The view created per model in `collection.models`. Defaults to __Giraffe.View__.
  * - [modelViewArgs] - {Array} The arguments passed to the `modelView` constructor. Can be a function returning an array.
  * - [modelViewEl] - {Selector,Giraffe.View#ui} The container for the model views. Can be a function returning the same. Defaults to `collectionView.$el`.
  *
  * @example
  *
  *  var FruitView = Giraffe.View.extend({});
  *
  *  var FruitsView = Giraffe.Contrib.CollectionView.extend({
  *    modelView: FruitView
  *  });
  *
  *  var view = new FruitsView({
  *    collection: [{name: 'apple'}],
  *  });
  *
  *  view.children.length; // => 1
  *
  *  view.collection.add({name: 'banana'});
  *
  *  view.children.length; // => 2
  */


  Contrib.CollectionView = (function(_super) {
    __extends(CollectionView, _super);

    CollectionView.getDefaults = function(ctx) {
      return {
        collection: ctx.collection ? null : new Giraffe.Collection,
        modelView: Giraffe.View,
        modelViewArgs: null,
        modelViewEl: null,
        renderOnChange: false
      };
    };

    function CollectionView() {
      var _ref, _ref1;
      CollectionView.__super__.constructor.apply(this, arguments);
      _.defaults(this, this.constructor.getDefaults(this));
      if (_.isArray(this.collection)) {
        this.collection = new Giraffe.Collection(this.collection);
      }
      if (!this.modelView) {
        throw new Error('`modelView` is required');
      }
      if (!((_ref = this.collection) != null ? _ref.model : void 0)) {
        throw new Error('`collection.model` is required');
      }
      this.listenTo(this.collection, 'add', this.addOne);
      this.listenTo(this.collection, 'remove', this.removeOne);
      this.listenTo(this.collection, 'reset sort', this.render);
      if (this.renderOnChange) {
        this.listenTo(this.collection, 'change', this._onChangeModel);
      }
      if (this.modelViewEl) {
        this.modelViewEl = ((_ref1 = this.ui) != null ? _ref1[this.modelViewEl] : void 0) || this.modelViewEl;
      }
    }

    CollectionView.prototype._onChangeModel = function(model) {
      var view;
      view = this.findByModel(model);
      return view.render();
    };

    CollectionView.prototype.findByModel = function(model) {
      var view, _i, _len, _ref;
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        view = _ref[_i];
        if (view.model === model) {
          return view;
        }
      }
      return null;
    };

    CollectionView.prototype._calcAttachOptions = function(model) {
      var i, index, options, prevModel, prevView;
      options = {
        el: null,
        method: 'prepend'
      };
      index = this.collection.indexOf(model);
      i = 1;
      while (prevModel = this.collection.at(index - i)) {
        prevView = this.findByModel(prevModel);
        if (prevView != null ? prevView._isAttached : void 0) {
          options.method = 'after';
          options.el = prevView.$el;
          break;
        }
        i++;
      }
      if (!options.el && this.modelViewEl) {
        options.el = this.$(this.modelViewEl);
        if (!options.el.length) {
          throw new Error('`modelViewEl` not found in this view');
        }
      }
      return options;
    };

    CollectionView.prototype._cloneModelViewArgs = function() {
      var args;
      args = this.modelViewArgs || [{}];
      if (_.isFunction(args)) {
        args = args.call(this);
      }
      if (!_.isArray(args)) {
        args = [args];
      }
      args = _.map(args, _.clone);
      if (!(_.isArray(args) && _.isObject(args[0]))) {
        throw new Error('`modelViewArgs` must be an array with an object as the first value');
      }
      return args;
    };

    CollectionView.prototype.afterRender = function() {
      var model, _i, _len, _ref;
      _ref = this.collection.models;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        model = _ref[_i];
        this.addOne(model);
      }
      return this;
    };

    CollectionView.prototype.removeOne = function(model, options) {
      var modelView;
      if (this.collection.contains(model)) {
        this.collection.remove(model);
      } else {
        modelView = _.findWhere(this.children, {
          model: model
        });
        if (modelView != null) {
          modelView.dispose();
        }
      }
      return this;
    };

    CollectionView.prototype.addOne = function(model) {
      var attachOptions, modelView, modelViewArgs;
      if (!this.collection.contains(model)) {
        this.collection.add(model);
      } else if (!this._renderedOnce) {
        this.render();
      } else {
        attachOptions = this._calcAttachOptions(model);
        modelViewArgs = this._cloneModelViewArgs();
        modelViewArgs[0].model = model;
        modelView = (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(this.modelView, modelViewArgs, function(){});
        this.attach(modelView, attachOptions);
      }
      return this;
    };

    return CollectionView;

  })(Giraffe.View);

  /*
  * A __FastCollectionView__ is a __CollectionView__ that _doesn't create a view
  * per model_. Performance should generally be improved, especially when the
  * entire collection must be rendered, as string concatenation is used to touch
  * the DOM once. [Here's a jsPerf with more.](http://jsperf.com/collection-views-in-giraffe-and-marionette/5)
  *
  * The option `modelEl` can be used to specify where to insert the model html.
  * It defaults to `view.$el` and cannot contain any DOM elemenets other
  * than those automatically created per model by the `FastCollectionView`.
  *
  * The option `modelTemplate` is the only required one and it is used to create
  * the html per model. ___`modelTemplate` must return a single top-level DOM node
  * per call.___ The __FVC__ uses a similar templating system to the
  * __Giraffe.View__, but instead of defining `template` and an optional 
  * `serialize` and templateStrategy`, __FVC__ takes  `modelTemplate` and optional
  * `modelSerialize` and `modelTemplateStrategy`. As in __Giraffe.View__,
  * setting `modelTemplateStrategy` to a function bypasses Giraffe's usage
  * of `modelTemplate` and `modelSerialize` to directly return a string of html.
  *
  * The __FVC__ reacts to the events `'add'`, `'remove'`, `'reset`', and `'sort'`.
  * It should keep `modelEl` in sync wih the collection with a template per model.
  * The __FVC__ API also exposes a shortcut to manipulating the collection with 
  * `addOne` and `removeOne`.
  *
  * @param {Object} options
  *
  * - [collection] - {Collection} The collection instance for the `FastCollectionView`. Defaults to a new __Giraffe.Collection__.
  * - modelTemplate - {String,Function} Required. The template for each model. Must return exactly 1 top level DOM element per call. Is actually not required if `modelTemplateStrategy` is a function, signaling circumvention of Giraffe's templating help.
  * - [modelTemplateStrategy] - {String} The template strategy used for the `modelTemplate`. Can be a function returning a string of HTML to override the need for `modelTemplate` and `modelSerialize`. Defaults to inheriting from the view.
  * - [modelSerialize] - {Function} Used to get the data passed to `modelTemplate`. Returns the model by default. Customize by passing as an option or override globally at `Giraffe.Contrib.FastCollectionView.prototype.modelSerialize`.
  * - [modelEl] - {Selector,Giraffe.View#ui} The selector or Giraffe.View#ui name for the model template container. Can be a function returning the same. Do not put html in here manually with the current design. Defaults to `view.$el`.
  *
  * @example
  *
  *  var FruitsView = Giraffe.Contrib.CollectionView.extend({
  *    modelTemplate: 'my-fcv-template-id'
  *  });
  *
  *  var view = new FruitsView({
  *    collection: [{name: 'apple'}],
  *  });
  *
  *  view.render();
  *
  *  view.$el.children().length; // => 1
  *
  *  var banana = new Backbone.Model({name: 'banana'});
  *
  *  view.collection.add(banana);
  *  // or
  *  // view.addOne(banana);
  *
  *  view.$el.children().length; // => 2
  *
  *  view.collection.remove(banana);
  *  // or
  *  // view.removeOne(banana);
  *
  *  view.$el.children().length; // => 1
  */


  Contrib.FastCollectionView = (function(_super) {
    __extends(FastCollectionView, _super);

    FastCollectionView.getDefaults = function(ctx) {
      return {
        collection: ctx.collection ? null : new Giraffe.Collection,
        modelTemplate: null,
        modelSerialize: ctx.modelSerialize ? null : function() {
          return this.model;
        },
        modelTemplateStrategy: ctx.templateStrategy,
        modelEl: null,
        renderOnChange: true
      };
    };

    function FastCollectionView() {
      var _ref;
      FastCollectionView.__super__.constructor.apply(this, arguments);
      if ((this.modelTemplate == null) && !_.isFunction(this.modelTemplateStrategy)) {
        throw new Error('`modelTemplate` or a `modelTemplateStrategy` function is required');
      }
      _.defaults(this, this.constructor.getDefaults(this));
      if (_.isArray(this.collection)) {
        this.collection = new Giraffe.Collection(this.collection);
      }
      this.listenTo(this.collection, 'add', this.addOne);
      this.listenTo(this.collection, 'remove', this.removeOne);
      this.listenTo(this.collection, 'reset sort', this.render);
      if (this.renderOnChange) {
        this.listenTo(this.collection, 'change', this.addOne);
      }
      if (this.modelEl) {
        this.modelEl = ((_ref = this.ui) != null ? _ref[this.modelEl] : void 0) || this.modelEl;
      }
      this.modelTemplateCtx = {
        serialize: this.modelSerialize,
        template: this.modelTemplate
      };
      Giraffe.View.setTemplateStrategy(this.modelTemplateStrategy, this.modelTemplateCtx);
    }

    FastCollectionView.prototype.afterRender = function() {
      this.$modelEl = this.modelEl ? this.$(this.modelEl) : this.$el;
      if (!this.$modelEl.length) {
        throw new Error('`$modelEl` not found after rendering');
      }
      this.addAll();
      return this;
    };

    /*
    * Removes `model` from the collection if present and removes its DOM elements.
    */


    FastCollectionView.prototype.removeOne = function(model, collection, options) {
      var index, _ref;
      if (this.collection.contains(model)) {
        this.collection.remove(model);
      } else {
        index = (_ref = options != null ? options.index : void 0) != null ? _ref : options;
        this.removeByIndex(index);
      }
      return this;
    };

    /*
    * Adds `model` to the collection if not present and renders it to the DOM.
    */


    FastCollectionView.prototype.addOne = function(model) {
      var html;
      if (!this.collection.contains(model)) {
        this.collection.add(model);
      } else if (!this._renderedOnce) {
        this.render();
      } else {
        html = this._renderModel(model);
        this._insertModelHTML(html, model);
      }
      return this;
    };

    /*
    * Adds all of the models to the DOM at once. Is destructive to `modelEl`.
    */


    FastCollectionView.prototype.addAll = function() {
      var html, model, _i, _len, _ref;
      html = '';
      _ref = this.collection.models;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        model = _ref[_i];
        html += this._renderModel(model);
      }
      this.$modelEl.empty()[0].innerHTML = html;
      return this;
    };

    /*
    * Removes children of `modelEl` by index.
    *
    * @param {Integer} index
    */


    FastCollectionView.prototype.removeByIndex = function(index) {
      var $el;
      $el = this.findElByIndex(index);
      if (!$el.length) {
        throw new Error('Unable to find el with index ' + index);
      }
      $el.remove();
      return this;
    };

    /*
    * Finds the element for `model`.
    *
    * @param {Model} model
    */


    FastCollectionView.prototype.findElByModel = function(model) {
      return this.findElByIndex(this.collection.indexOf(model));
    };

    /*
    * Finds the element inside `modelEl` at `index`.
    *
    * @param {Integer} index
    */


    FastCollectionView.prototype.findElByIndex = function(index) {
      return $(this.$modelEl.children()[index]);
    };

    /*
    * Finds the corresponding model in the collection by a DOM element.
    * Is especially useful in DOM handlers - pass `event.target` to get the model.
    *
    * @param {String/Element/$/Giraffe.View} el
    */


    FastCollectionView.prototype.findModelByEl = function(el) {
      var index;
      index = $(el).closest(this.$modelEl.children()).index();
      return this.collection.at(index);
    };

    /*
    * Generates a model's html string using `modelTemplateCtx` and its options.
    */


    FastCollectionView.prototype._renderModel = function(model) {
      this.modelTemplateCtx.model = model;
      return this.modelTemplateCtx.templateStrategy();
    };

    /*
    * Inserts a model's html into the DOM.
    */


    FastCollectionView.prototype._insertModelHTML = function(html, model) {
      var $children, $existingEl, $prevModel, index, numChildren;
      $children = this.$modelEl.children();
      numChildren = $children.length;
      index = this.collection.indexOf(model);
      if (numChildren === this.collection.length) {
        $existingEl = $($children[index]);
        $existingEl.replaceWith(html);
      } else if (index >= numChildren) {
        this.$modelEl.append(html);
      } else {
        $prevModel = $($children[index - 1]);
        if ($prevModel.length) {
          $prevModel.after(html);
        } else {
          this.$modelEl.prepend(html);
        }
      }
      return this;
    };

    return FastCollectionView;

  })(Giraffe.View);

  if (_.isObject(typeof module !== "undefined" && module !== null ? module.exports : void 0)) {
    module.exports = Contrib;
  } else if (typeof define === 'function' && define.amd) {
    define('backbone.giraffe.contrib', [], function() {
      return Contrib;
    });
  }

}).call(this);
