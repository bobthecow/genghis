(function() {
  var $, $document, $window, Backbone, Giraffe, error, _, _afterInitialize, _setEventBindings, _setEventMapBindings,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  $ = window.$, _ = window._, Backbone = window.Backbone;

  if (!_) {
    _ = typeof require === "function" ? require('underscore') : void 0;
    if (!_) {
      throw new Error('Can\'t find underscore');
    }
  }

  if (!Backbone) {
    Backbone = typeof require === "function" ? require('backbone') : void 0;
    if (!Backbone) {
      throw new Error('Can\'t find Backbone');
    }
  }

  Backbone.Giraffe = window.Giraffe = Giraffe = {
    version: '0.2.4',
    app: null,
    apps: {},
    views: {}
  };

  $window = $(window);

  $document = $(document);

  error = function() {
    var _ref, _ref1;
    return typeof console !== "undefined" && console !== null ? (_ref = console.error) != null ? _ref.apply(console, (_ref1 = ['Backbone.Giraffe error:']).concat.apply(_ref1, arguments)) : void 0 : void 0;
  };

  /*
  * __Giraffe.View__ is optimized for simplicity and flexibility. Views can move
  * around the DOM safely and freely with the `attachTo` method, which accepts any
  * selector, DOM element, or view, as well as an optional __jQuery__ insertion
  * method like `'prepend'`, `'after'`, or `'html'`. The default is `'append'`.
  *
  *     var parentView = new Giraffe.View();
  *     parentView.attachTo('body', {method: 'prepend'});
  *     $('body').find(parentView.$el).length; // => 1
  *
  * The `attachTo` method automatically sets up parent-child relationships between
  * views via the references `children` and `parent` to allow nesting with no
  * extra work.
  *
  *     var childView = new Giraffe.View();
  *     childView.attachTo(parentView); // or `parentView.attach(childView);`
  *     childView.parent === parentView; // => true
  *     parentView.children[0] === childView; // => true
  *
  * Views automatically manage the lifecycle of all `children`, and any object
  * with a `dispose` method can be added to `children` via `addChild`.
  * When a view is disposed, it disposes of all of its `children`, allowing the
  * disposal of an entire application with a single method call.
  *
  *     parentView.dispose(); // disposes both `parentView` and `childView`
  *
  * When a view is attached, `render` is called if it has not yet been rendered.
  * When a view renders, it first calls `detach` on all of its `children`, and
  * when a view is detached, the default behavior is to call `dispose` on it.
  * To overried this behavior and cache a view even when its `parent` renders, you
  * can set the cached view's `disposeOnDetach` property to `false`.
  *
  *     var parentView = new Giraffe.View();
  *     parentView.attach(new Giraffe.View());
  *     parentView.attach(new Giraffe.View({disposeOnDetach: false}));
  *     parentView.attachTo('body'); // render() is called, disposes of the first view
  *     parentView.children.length; // => 1
  *
  * Views are not automatically reattached after `render`, so you retain control,
  * but their parent-child relationships stay intact unless they're disposed.
  * See [`Giraffe.View#afterRender`](#View-afterRender) for more.
  *
  * __Giraffe.View__ gets much of its smarts by way of the `data-view-cid`
  * attribute attached to `view.$el`. This attribute allows us to find a view's
  * parent when attached to a DOM element and safely detach views when they would
  * otherwise be clobbered.
  *
  * Currently, __Giraffe__ has only one class that extends __Giraffe.View__,
  * __Giraffe.App__, which encapsulates app-wide messaging and routing.
  *
  * Like all __Giraffe__ objects, __Giraffe.View__ extends each instance with
  * every property in `options`.
  *
  * @param {Object} [options]
  */


  Giraffe.View = (function(_super) {
    __extends(View, _super);

    View.defaultOptions = {
      disposeOnDetach: true
    };

    function View(options) {
      this.render = __bind(this.render, this);
      Giraffe.configure(this, options);
      /*
      * When one view is attached to another, the child view is added to the
      * parent's `children` array. When `dispose` is called on a view, it disposes
      * of all `children`, enabling the teardown of a single view or an entire app
      * with one method call. Any object with a `dispose` method can be added
      * to a view's `children` via `addChild` to take advantage of lifecycle
      * management.
      */

      this.children = [];
      /*
      * Child views attached via `attachTo` have a reference to their parent view.
      */

      this.parent = null;
      this._renderedOnce = false;
      this._isAttached = false;
      this._createEventsFromUIElements();
      if (typeof this.templateStrategy === 'string') {
        Giraffe.View.setTemplateStrategy(this.templateStrategy, this);
      }
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.beforeInitialize = function() {
      this._cache();
      this.$el.attr('data-view-cid', this.cid);
      this.setParent(Giraffe.View.getClosestView(this.$el));
      return this._cacheUiElements();
    };

    View.prototype._attachMethods = ['append', 'prepend', 'html', 'after', 'before', 'insertAfter', 'insertBefore'];

    View.prototype._siblingAttachMethods = ['after', 'before', 'insertAfter', 'insertBefore'];

    /*
    * Attaches this view to `el`, which can be a selector, DOM element, or view.
    * If `el` is inside another view, a parent-child relationship is set up.
    * `options.method` is the __jQuery__ method used to attach the view. It
    * defaults to `'append'` and also accepts `'prepend'`, `'after'`, `'before'`,
    * and `'html'`. If the view has not yet been rendered when attached, `render`
    * is called. This `render` behavior can be overridden via
    * `options.forceRender` and `options.suppressRender`. See the
    * [_View Basics_ example](viewBasics.html) for more.
    * Triggers `attaching` and `attached` events.
    *
    * @param {String/Element/$/Giraffe.View} el A view, selector, or DOM element to attach `view.$el` to.
    * @param {Object} [options]
    *     {String} method The jQuery method used to put this view in `el`. Accepts `'append'`, `'prepend'`, `'html'`, `'after'`, and `'before'`. Defaults to `'append'`.
    *     {Boolean} forceRender Calls `render` when attached, even if the view has already been rendered.
    *     {Boolean} suppressRender Prevents `render` when attached, even if the view hasn't yet been rendered.
    */


    View.prototype.attachTo = function(el, options) {
      var $container, $el, forceRender, method, shouldRender, suppressRender;
      method = (options != null ? options.method : void 0) || 'append';
      forceRender = (options != null ? options.forceRender : void 0) || false;
      suppressRender = (options != null ? options.suppressRender : void 0) || false;
      if (!this.$el) {
        error('Trying to attach a disposed view. Make a new one or create the view with the option `disposeOnDetach` set to false.', this);
        return this;
      }
      if (!_.contains(this._attachMethods, method)) {
        error("The attach method '" + method + "' isn't supported. Defaulting to 'append'.", method, this._attachMethods);
        method = 'append';
      }
      $el = Giraffe.View.to$El(el);
      if ($el.length !== 1) {
        error('Expected to render to a single element but found ' + $el.length, el);
        return this;
      }
      this.trigger('attaching', this, $el, options);
      $container = _.contains(this._siblingAttachMethods, method) ? $el.parent() : $el;
      if (method === 'insertAfter') {
        method = 'after';
      }
      if (method === 'insertBefore') {
        method = 'before';
      }
      this.detach(true);
      this.setParent(Giraffe.View.getClosestView($container));
      if (method === 'html') {
        Giraffe.View.detachByEl($el);
        $el.empty();
      }
      $el[method](this.$el);
      this._isAttached = true;
      shouldRender = !suppressRender && (!this._renderedOnce || forceRender || this.alwaysRender);
      if (shouldRender) {
        this.render(options);
      }
      if (this.saveScrollPosition) {
        this._loadScrollPosition();
      }
      if (this.documentTitle != null) {
        document.title = this.documentTitle;
      }
      this.trigger('attached', this, $el, options);
      return this;
    };

    /*
    * `attach` is an inverted way to call `attachTo`. Unlike `attachTo`, calling
    * this function requires a parent view. It's here only for aesthetics. Takes
    * the same `options` as `attachTo` in addition to the optional `options.el`,
    * which is the first argument passed to `attachTo`, defaulting to the parent
    * view.
    *
    * @param {View} view
    * @param {Object} [options]
    * @caption parentView.attach(childView, [options])
    */


    View.prototype.attach = function(view, options) {
      var childEl, target;
      target = null;
      if (options != null ? options.el : void 0) {
        childEl = Giraffe.View.to$El(options.el, this.$el, true);
        if (childEl.length) {
          target = childEl;
        } else {
          error('Attempting to attach to an element that doesn\'t exist inside this view!', options, view, this);
          return this;
        }
      } else {
        target = this.$el;
      }
      view.attachTo(target, options);
      return this;
    };

    /*
    * __Giraffe__ implements `render` so it can do some helpful things, but you can
    * still call it like you normally would. By default, `render` uses a view's
    * `template`, which is the DOM selector of an __Underscore__ template, but
    * this is easily configured. See [`Giraffe.View#template`](#View-template),
    * [`Giraffe.View.setTemplateStrategy`](#View-setTemplateStrategy), and
    * [`Giraffe.View#templateStrategy`](#View-templateStrategy) for more.
    *
    * @caption Do not override unless you know what you're doing!
    */


    View.prototype.render = function(options) {
      var html;
      this.trigger('rendering', this, options);
      this.beforeRender.apply(this, arguments);
      this._renderedOnce = true;
      this.detachChildren(options != null ? options.preserve : void 0);
      html = this.templateStrategy.apply(this, arguments) || '';
      this.$el.empty()[0].innerHTML = html;
      this._cacheUiElements();
      this.afterRender.apply(this, arguments);
      this.trigger('rendered', this, options);
      return this;
    };

    /*
    * This is an empty function for you to implement. Less commonly used than
    * `afterRender`, but helpful in circumstances where the DOM has state that
    * needs to be preserved across renders. For example, if a view with a dropdown
    * menu is rendering, you may want to save its open state in `beforeRender`
    * and reapply it in `afterRender`.
    *
    * @caption Implement this function in your views.
    */


    View.prototype.beforeRender = function() {};

    /*
    * This is an empty function for you to implement. After a view renders,
    * `afterRender` is called. Child views are normally attached to the DOM here.
    * Views that are cached by setting `disposeOnDetach` to true will be
    * in `view.children` in `afterRender`, but will not be attached to the
    * parent's `$el`.
    *
    * @caption Implement this function in your views.
    */


    View.prototype.afterRender = function() {};

    /*
    * __Giraffe__ implements its own `render` function which calls `templateStrategy`
    * to get the HTML string to put inside `view.$el`. Your views can either
    * define a `template`, which uses __Underscore__ templates by default and is
    * customizable via [`Giraffe.View#setTemplateStrategy`](#View-setTemplateStrategy),
    * or override `templateStrategy` with a function returning a string of HTML
    * from your favorite templating engine. See the
    * [_Template Strategies_ example](templateStrategies.html) for more.
    */


    View.prototype.templateStrategy = function() {
      return '';
    };

    /*
    * Consumed by the `templateStrategy` function created by
    * [`Giraffe.View#setTemplateStrategy`](#View-setTemplateStrategy). By default,
    * `template` is the DOM selector of an __Underscore__ template. See the
    * [_Template Strategies_ example](templateStrategies.html) for more.
    *
    *     // the default `templateStrategy` is 'underscore-template-selector'
    *     view.template = '#my-template-selector';
    *     // or
    *     Giraffe.View.setTemplateStrategy('underscore-template');
    *     view.template = '<div>hello <%= name %></div>';
    *     // or
    *     Giraffe.View.setTemplateStrategy('jst');
    *     view.template = function(data) { return '<div>hello' + data.name + '</div>'};
    */


    View.prototype.template = null;

    /*
    * Gets the data passed to the `template`. Returns the view by default.
    *
    * @caption Override this function to pass custom data to a view's `template`.
    */


    View.prototype.serialize = function() {
      return this;
    };

    /*
    * Detaches the view from the DOM. If `view.disposeOnDetach` is true,
    * which is the default, `dispose` will be called on the view and its
    * `children` unless `preserve` is true. `preserve` defaults to false. When
    * a view renders, it first calls `detach(false)` on the views inside its `$el`.
    *
    * @param {Boolean} [preserve] If true, doesn't dispose of the view, even if `disposeOnDetach` is `true`.
    */


    View.prototype.detach = function(preserve) {
      if (preserve == null) {
        preserve = false;
      }
      if (!this._isAttached) {
        return this;
      }
      this._isAttached = false;
      if (this.saveScrollPosition) {
        this._saveScrollPosition();
      }
      this.trigger('detaching', this, preserve);
      this.$el.detach();
      this.trigger('detached', this, preserve);
      if (this.disposeOnDetach && !preserve) {
        this.dispose();
      }
      return this;
    };

    /*
    * Calls `detach` on each object in `children`, passing `preserve` through.
    *
    * @param {Boolean} [preserve]
    */


    View.prototype.detachChildren = function(preserve) {
      var child, _i, _len, _ref;
      if (preserve == null) {
        preserve = false;
      }
      _ref = this.children.slice();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (typeof child.detach === "function") {
          child.detach(preserve);
        }
      }
      return this;
    };

    View.prototype._saveScrollPosition = function() {
      this._scrollPosition = this._getScrollPositionEl().scrollTop();
      return this;
    };

    View.prototype._loadScrollPosition = function() {
      if (this._scrollPosition != null) {
        this._getScrollPositionEl().scrollTop(this._scrollPosition);
      }
      return this;
    };

    View.prototype._getScrollPositionEl = function() {
      var $el;
      if (typeof this.saveScrollPosition === 'boolean' || this.$el.is(this.saveScrollPosition)) {
        return this.$el;
      } else {
        $el = Giraffe.View.to$El(this.saveScrollPosition, this.$el).first();
        if ($el.length) {
          return $el;
        } else {
          $el = Giraffe.View.to$El(this.saveScrollPosition).first();
          if ($el.length) {
            return $el;
          } else {
            return this.$el;
          }
        }
      }
    };

    /*
    * Adds `child` to this view's `children` and assigns this view as
    * `child.parent`. If `child` implements `dispose`, it will be called when the
    * view is disposed. If `child` implements `detach`, it will be called before
    * the view renders.
    *
    * @param {Object} child
    */


    View.prototype.addChild = function(child) {
      var _ref;
      if (!_.contains(this.children, child)) {
        if ((_ref = child.parent) != null) {
          _ref.removeChild(child, true);
        }
        child.parent = this;
        this.children.push(child);
      }
      return this;
    };

    /*
    * Calls `addChild` on the given array of objects.
    *
    * @param {Array} children Array of objects
    */


    View.prototype.addChildren = function(children) {
      var child, _i, _len;
      for (_i = 0, _len = children.length; _i < _len; _i++) {
        child = children[_i];
        this.addChild(child);
      }
      return this;
    };

    /*
    * Removes an object from this view's `children`. If `preserve` is `false`, the
    * default, __Giraffe__ will attempt to call `dispose` on the child. If
    * `preserve` is true, __Giraffe__ will attempt to call `detach(true)` on the
    * child.
    *
    * @param {Object} child
    * @param {Boolean} [preserve] If `true`, Giraffe attempts to call `detach` on the child, otherwise it attempts to call `dispose` on the child. Is `false` by default.
    */


    View.prototype.removeChild = function(child, preserve) {
      var index;
      if (preserve == null) {
        preserve = false;
      }
      index = _.indexOf(this.children, child);
      if (index !== -1) {
        this.children.splice(index, 1);
        child.parent = null;
        if (preserve) {
          if (typeof child.detach === "function") {
            child.detach(true);
          }
        } else {
          if (typeof child.dispose === "function") {
            child.dispose();
          }
        }
      }
      return this;
    };

    /*
    * Calls `removeChild` on all `children`, passing `preserve` through.
    *
    * @param {Boolean} [preserve] If `true`, detaches rather than removes the children.
    */


    View.prototype.removeChildren = function(preserve) {
      var child, _i, _len, _ref;
      if (preserve == null) {
        preserve = false;
      }
      _ref = this.children.slice();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        this.removeChild(child, preserve);
      }
      return this;
    };

    /*
    * Sets a new parent for a view, first removing any current parent-child
    * relationship. `parent` can be falsy to remove the current parent.
    *
    * @param {Giraffe.View} [parent]
    */


    View.prototype.setParent = function(parent) {
      if (parent && parent !== this) {
        parent.addChild(this);
      } else if (this.parent) {
        this.parent.removeChild(this, true);
        this.parent = null;
      }
      return this;
    };

    /*
    * If `el` is `null` or `undefined`, tests if the view is somewhere on the DOM
    * by calling `$document.find(view.$el)`. If `el` is a view, tests if `el` contains
    * this view. Otherwise, tests if `el` is the immediate parent of `view.$el`.
    *
    * @param {String} [el] Optional selector, DOM element, or view to test against the view's immediate parent.
    * @returns {Boolean}
    */


    View.prototype.isAttached = function(el) {
      if (el != null) {
        if (el.$el) {
          return !!el.$el.find(this.$el).length;
        } else {
          return this.$el.parent().is(el);
        }
      } else {
        return !!$document.find(this.$el).length;
      }
    };

    /*
    * `ui` is an optional view property that helps DRY up DOM references in views.
    * It provides a convenient way to cache __jQuery__ objects after every `render`,
    * and the names given to these objects can be used in `Backbone.View#events`.
    * Declaring `this.ui = {$button: '#button'}` in a view makes `this.$button`
    * always available once `render` has been called. Typically the `ui` value is
    * a string which is then searched for inside `this.$el`, but if it's a
    * function, its return value will be assigned. If it's neither a string nor a
    * function, the value itself is assigned.
    *
    *     Giraffe.View.extend({
    *       ui: {
    *         $someButton: '#some-button-selector'
    *       },
    *       afterRender: {
    *         this.$someButton; // just got cached
    *       },
    *       events: {
    *         '#click $someButton': 'onClickSomeButton' // ui names work here
    *       }
    *     });
    */


    View.prototype.ui = null;

    View.prototype._cacheUiElements = function() {
      var name, selector, _ref;
      if (this.ui) {
        _ref = this.ui;
        for (name in _ref) {
          selector = _ref[name];
          this[name] = (function() {
            switch (typeof selector) {
              case 'string':
                return this.$(selector);
              case 'function':
                return selector.call(this);
              default:
                return selector;
            }
          }).call(this);
        }
      }
      return this;
    };

    View.prototype._uncacheUiElements = function() {
      var name;
      if (this.ui) {
        for (name in this.ui) {
          delete this[name];
        }
      }
      return this;
    };

    View.prototype._createEventsFromUIElements = function() {
      var eventKey, method, newEventKey, _ref;
      if (!(this.events && this.ui)) {
        return this;
      }
      if (typeof this.ui === 'function') {
        this.ui = this.ui.call(this);
      }
      if (typeof this.events === 'function') {
        this.events = this.events.call(this);
      }
      _ref = this.events;
      for (eventKey in _ref) {
        method = _ref[eventKey];
        newEventKey = this._getEventKeyFromUIElements(eventKey);
        if (newEventKey !== eventKey) {
          delete this.events[eventKey];
          this.events[newEventKey] = method;
        }
      }
      return this;
    };

    View.prototype._getEventKeyFromUIElements = function(eventKey) {
      var lastPart, length, parts, uiTarget;
      parts = eventKey.split(' ');
      length = parts.length;
      if (length < 2) {
        return eventKey;
      }
      lastPart = parts[length - 1];
      uiTarget = this.ui[lastPart];
      if (uiTarget) {
        parts[length - 1] = uiTarget;
        return parts.join(' ');
      } else {
        return eventKey;
      }
    };

    /*
    * Inspired by `Backbone.View#events`, `dataEvents` binds a space-separated
    * list of events ending with the target object to methods on a view.
    * It is a shorthand way of calling `view.listenTo(targetObj, event, cb)`.
    * In this example `collection` is used, but any object on the view that
    * implements __Backbone.Events__ is a valid target object. To have a view
    * listen to itself, the keywords `'this'` and `'@'` can be used.
    *
    *     Giraffe.View.extend({
    *       dataEvents: {
    *         'add remove change collection': 'render',
    *         'event anotherEvent targetObj': function() {},
    *         'eventOnThisView @': 'methodName'
    *       }
    *     });
    *
    * As a result of using `listenTo`, `dataEvents` accepts multiple events per
    * definition, handlers are called in the context of the view, and
    * bindings are cleaned up in `dispose` via `stopListening`.
    *
    * There are some unfortunate restrictions to `dataEvents`. Objects created
    * after `initialize` will not be bound to, and events fired during the
    * `constructor` and `initialize` will not be heard. We advocate using
    * `Backbone.Events#listenTo` directly in these circumstances.
    *
    * See the [__Data Events__ example](dataEvents.html) for more.
    */


    View.prototype.dataEvents = null;

    View.prototype._uncache = function() {
      delete Giraffe.views[this.cid];
      return this;
    };

    View.prototype._cache = function() {
      Giraffe.views[this.cid] = this;
      return this;
    };

    /*
    * Calls `methodName` on the view, or if not found, up the view hierarchy until
    * it either finds the method or fails on a view without a `parent`. Used by
    * __Giraffe__ to call the methods defined for the events bound in
    * `Giraffe.View.setDocumentEvents`.
    *
    * @param {String} methodName
    * @param {Any} [args...]
    */


    View.prototype.invoke = function() {
      var args, methodName, view;
      methodName = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      view = this;
      while (view && !view[methodName]) {
        view = view.parent;
      }
      if (view != null ? view[methodName] : void 0) {
        return view[methodName].apply(view, args);
      } else {
        error('No such method name in view hierarchy', methodName, args, this);
        return false;
      }
    };

    /*
    * See [`Giraffe.App#appEvents`](#App-appEvents).
    */


    View.prototype.appEvents = null;

    /*
    * Destroys a view, unbinding its events and freeing its resources. Calls
    * `Backbone.View#remove` and calls `dispose` on all `children`.
    */


    View.prototype.beforeDispose = function() {
      this.setParent(null);
      this.removeChildren();
      this._uncacheUiElements();
      this._uncache();
      this._isAttached = false;
      if (this.$el) {
        this.remove();
        this.$el = null;
      } else {
        error('Disposed of a view that has already been disposed', this);
      }
      return this;
    };

    /*
    * Detaches the top-level views inside `el`, which can be a selector, element,
    * or __Giraffe.View__. Used internally by __Giraffe__ to remove views that
    * would otherwise be clobbered when the option `method: 'html'` is used
    * in `attachTo`. Uses the `data-view-cid` attribute to match DOM nodes to view
    * instances.
    *
    * @param {String/Element/$/Giraffe.View} el
    * @param {Boolean} [preserve]
    */


    View.detachByEl = function(el, preserve) {
      var $child, $el, cid, view;
      if (preserve == null) {
        preserve = false;
      }
      $el = Giraffe.View.to$El(el);
      while (($child = $el.find('[data-view-cid]:first')).length) {
        cid = $child.attr('data-view-cid');
        view = Giraffe.View.getByCid(cid);
        view.detach(preserve);
      }
      return this;
    };

    /*
    * Gets the closest parent view of `el`, which can be a selector, element, or
    * __Giraffe.View__. Uses the `data-view-cid` attribute to match DOM nodes to
    * view instances.
    *
    * @param {String/Element/$/Giraffe.View} el
    */


    View.getClosestView = function(el) {
      var $el, cid;
      $el = Giraffe.View.to$El(el);
      cid = $el.closest('[data-view-cid]').attr('data-view-cid');
      return Giraffe.View.getByCid(cid);
    };

    /*
    * Looks up a view from the cache by `cid`, returning undefined if not found.
    *
    * @param {String} cid
    */


    View.getByCid = function(cid) {
      return Giraffe.views[cid];
    };

    /*
    * Gets a __jQuery__ object from `el`, which can be a selector, element,
    * __jQuery__ object, or __Giraffe.View__, scoped by an optional `parent`,
    * which has the same available types as `el`. If the third parameter is
    * truthy, `el` can be the same element as `parent`.
    *
    * @param {String/Element/$/Giraffe.View} el
    * @param {String/Element/$/Giraffe.View} [parent] Opitional. Scopes `el` if provided.
    * @param {Boolean} [allowParentMatch] Optional. If truthy, `el` can be `parent`.
    */


    View.to$El = function(el, parent, allowParentMatch) {
      var $parent;
      if (allowParentMatch == null) {
        allowParentMatch = false;
      }
      if (parent) {
        $parent = Giraffe.View.to$El(parent);
        if (el != null ? el.$el : void 0) {
          el = el.$el;
        }
        if (allowParentMatch && $parent.is(el)) {
          return $parent;
        } else {
          return $parent.find(el);
        }
      } else if (el != null ? el.$el : void 0) {
        return el.$el;
      } else if (el instanceof $) {
        return el;
      } else {
        return $(el);
      }
    };

    /*
    * __Giraffe__ provides a convenient high-performance way to declare view
    * method calls in your HTML markup. Using the form
    * `data-gf-eventName='methodName'`, when a bound DOM event is triggered,
    * __Giraffe__ looks for the defined method on the element's view. For example,
    * putting `data-gf-click='onSubmitForm'` on a button calls the method
    * `onSubmitForm` on its view on `'click'`. If the view does not define the
    * method, __Giraffe__ searches up the view hierarchy until it finds it or runs
    * out of views. By default, only the `click` and `change` events are bound by
    * __Giraffe__, but `setDocumentEvents` allows you to set a custom list of
    * events, first unbinding the existing ones and then setting the ones you give
    * it, if any.
    *
    *     Giraffe.View.setDocumentEvents(['click', 'change']); // default
    *     // or
    *     Giraffe.View.setDocumentEvents(['click', 'change', 'keydown']);
    *     // or
    *     Giraffe.View.setDocumentEvents('click change keydown keyup');
    *
    * @param {Array/String} events An array or space-separated string of DOM events to bind to the document.
    */


    View.setDocumentEvents = function(events, prefix) {
      var attr, event, selector, _fn, _i, _len;
      if (prefix == null) {
        prefix = Giraffe.View._documentEventPrefix;
      }
      prefix = prefix || '';
      if (typeof events === 'string') {
        events = events.split(' ');
      }
      if (!_.isArray(events)) {
        events = [events];
      }
      events = _.compact(events);
      Giraffe.View.removeDocumentEvents();
      Giraffe.View._currentDocumentEvents = events;
      Giraffe.View._documentEventPrefix = prefix;
      _fn = function(event, attr, selector) {
        return $document.on(event, selector, function(e) {
          var $target, method, view;
          $target = $(e.target).closest(selector);
          method = $target.attr(attr);
          view = Giraffe.View.getClosestView($target);
          return view.invoke(method, e);
        });
      };
      for (_i = 0, _len = events.length; _i < _len; _i++) {
        event = events[_i];
        attr = prefix + event;
        selector = '[' + attr + ']';
        _fn(event, attr, selector);
      }
      return events;
    };

    /*
    * Equivalent to `Giraffe.View.setDocumentEvents(null)`.
    */


    View.removeDocumentEvents = function(prefix) {
      var currentEvents, event, selector, _i, _len;
      if (prefix == null) {
        prefix = Giraffe.View._documentEventPrefix;
      }
      prefix = prefix || '';
      currentEvents = Giraffe.View._currentDocumentEvents;
      if (!(currentEvents != null ? currentEvents.length : void 0)) {
        return;
      }
      for (_i = 0, _len = currentEvents.length; _i < _len; _i++) {
        event = currentEvents[_i];
        selector = '[' + prefix + event + ']';
        $document.off(event, selector);
      }
      return Giraffe.View._currentDocumentEvents = null;
    };

    /*
    * Sets the prefix for document events. Defaults to `data-gf-`,
    * so to bind to `'click'` events, one would put the `data-gf-click`
    * attribute on DOM elements with the name of a view method as the value.
    *
    * @param {String} prefix If `null` or `undefined`, defaults to the empty string.
    */


    View.setDocumentEventPrefix = function(prefix) {
      if (prefix == null) {
        prefix = '';
      }
      return Giraffe.View.setDocumentEvents(Giraffe.View._currentDocumentEvents, prefix);
    };

    /*
    * Giraffe provides common strategies for templating.
    *
    * The `strategy` argument can be a function returning an HTML string or one of the following:
    *
    * - `'underscore-template-selector'`
    *
    *     - `view.template` is a string or function returning DOM selector
    *
    * - `'underscore-template'`
    *
    *     - `view.template` is a string or function returning underscore template
    *
    * - `'jst'`
    *
    *     - `view.template` is an html string or a JST function
    *
    * See the [_Template Strategies_ example](templateStrategies.html) for more.
    *
    * @param {String} strategy Choose 'underscore-template-selector', 'underscore-template', 'jst'
    *
    */


    View.setTemplateStrategy = function(strategy, instance) {
      var strategyType, templateStrategy;
      strategyType = typeof strategy;
      if (strategyType === 'function') {
        templateStrategy = strategy;
      } else if (strategyType !== 'string') {
        return error('Unrecognized template strategy', strategy);
      } else {
        switch (strategy.toLowerCase()) {
          case 'underscore-template-selector':
            templateStrategy = function() {
              var selector,
                _this = this;
              if (!this.template) {
                return '';
              }
              if (!this._templateFn) {
                switch (typeof this.template) {
                  case 'string':
                    selector = this.template;
                    this._templateFn = _.template($(selector).html() || '');
                    break;
                  case 'function':
                    this._templateFn = function(locals) {
                      selector = _this.template();
                      return _.template($(selector).html() || '', locals);
                    };
                    break;
                  default:
                    throw new Error('this.template must be string or function');
                }
              }
              return this._templateFn(this.serialize.apply(this, arguments));
            };
            break;
          case 'underscore-template':
            templateStrategy = function() {
              var _this = this;
              if (!this.template) {
                return '';
              }
              if (!this._templateFn) {
                switch (typeof this.template) {
                  case 'string':
                    this._templateFn = _.template(this.template);
                    break;
                  case 'function':
                    this._templateFn = function(locals) {
                      return _.template(_this.template(), locals);
                    };
                    break;
                  default:
                    throw new Error('this.template must be string or function');
                }
              }
              return this._templateFn(this.serialize.apply(this, arguments));
            };
            break;
          case 'jst':
            templateStrategy = function() {
              var html;
              if (!this.template) {
                return '';
              }
              if (!this._templateFn) {
                switch (typeof this.template) {
                  case 'string':
                    html = this.template;
                    this._templateFn = function() {
                      return html;
                    };
                    break;
                  case 'function':
                    this._templateFn = this.template;
                    break;
                  default:
                    throw new Error('this.template must be string or function');
                }
              }
              return this._templateFn(this.serialize.apply(this, arguments));
            };
            break;
          default:
            throw new Error('Unrecognized template strategy: ' + strategy);
        }
      }
      if (instance) {
        return instance.templateStrategy = templateStrategy;
      } else {
        return Giraffe.View.prototype.templateStrategy = templateStrategy;
      }
    };

    return View;

  })(Backbone.View);

  Giraffe.View.setTemplateStrategy('underscore-template-selector');

  Giraffe.View.setDocumentEvents(['click', 'change'], 'data-gf-');

  /*
  * __Giraffe.App__ is a special __Giraffe.View__ that provides encapsulation for
  * an entire application. Like all __Giraffe__ views, the app has lifecycle
  * management for all `children`, so calling `dispose` on an app will call
  * `dispose` on all `children` that have the method. The first __Giraffe.App__
  * created on a page is available globally at `Giraffe.app`, and by default all
  * __Giraffe__ objects reference this app as `this.app` unless they're passed a
  * different app in `options.app`. This app reference is used to bind
  * `appEvents`, a hash that all __Giraffe__ objects can implement which uses the
  * app as an event aggregator for communication and routing.
  *
  *     var myApp = new Giraffe.App();
  *     window.Giraffe.app; // => `myApp`
  *     myApp.attach(new Giraffe.View({
  *       appEvents: {
  *         'say:hello': function() { console.log('hello world'); }
  *       },
  *       // app: someOtherApp // if you don't want to use `window.Giraffe.app`
  *     }));
  *     myApp.trigger('say:hello'); // => 'hello world'
  *
  * `appEvents` are also used by the __Giraffe.Router__. See
  * [`Giraffe.App#routes`](#App-routes) for more.
  *
  * The app also provides synchronous and asynchronous initializers with `addInitializer` and `start`.
  *
  * Like all __Giraffe__ objects, __Giraffe.App__ extends each instance with
  * every property in `options`.
  *
  * @param {Object} [options]
  */


  Giraffe.App = (function(_super) {
    __extends(App, _super);

    function App(options) {
      this._onUnload = __bind(this._onUnload, this);
      this.app = this;
      this._initializers = [];
      this.started = false;
      App.__super__.constructor.apply(this, arguments);
    }

    App.prototype._cache = function() {
      if (Giraffe.app == null) {
        Giraffe.app = this;
      }
      Giraffe.apps[this.cid] = this;
      if (this.routes) {
        if (this.router == null) {
          this.router = new Giraffe.Router({
            app: this,
            triggers: this.routes
          });
        }
      }
      $window.on('unload', this._onUnload);
      return App.__super__._cache.apply(this, arguments);
    };

    App.prototype._uncache = function() {
      if (Giraffe.app === this) {
        Giraffe.app = null;
      }
      delete Giraffe.apps[this.cid];
      if (this.router) {
        this.router = null;
      }
      $window.off('unload', this._onUnload);
      return App.__super__._uncache.apply(this, arguments);
    };

    App.prototype._onUnload = function() {
      return this.dispose();
    };

    /*
    * Similar to the `events` hash of __Backbone.View__, `appEvents` maps events
    * on `this.app` to methods on a __Giraffe__ object. App events can be
    * triggered from routes or by any object in your application. If a
    * __Giraffe.App__ has been created, every __Giraffe__ object has a reference
    * to the global __Giraffe.app__ instance at `this.app`, and a specific app
    * instance can be set by passing `options.app` to the object's constructor.
    * This instance of `this.app` is used to bind `appEvents`, and these bindings
    * are automatically cleaned up when an object is disposed.
    *
    *     // in a Giraffe object
    *     this.appEvents = {'some:appEvent': 'someMethod'};
    *     this.app.trigger('some:appEvent', params) // => this.someMethod(params)
    */


    App.prototype.appEvents = null;

    /*
    * If `routes` is defined on a __Giraffe.App__ or passed to its constructor
    * as an option, the app will create an instance of __Giraffe.Router__ as
    * `this.router` and set the router's `triggers` to the app's `routes`. Any
    * number of routers can be instantiated manually, but they do require that an
    * instance of __Giraffe.App__ is first created, because they use `appEvents`
    * for route handling. See [`Giraffe.Router#triggers`](#Router-triggers)
    * for more.
    *
    *     var app = new Giraffe.App({routes: {'route': 'appEvent'}});
    *     app.router; // => instance of Giraffe.Router
    *     // or
    *     var MyApp = Giraffe.App.extend({routes: {'route': 'appEvent'}});
    *     var myApp = new MyApp();
    *     myApp.router; // => instance of Giraffe.Router
    */


    App.prototype.routes = null;

    /*
    * Queues up the provided function to be run on `start`. The functions you
    * provide are called with the same `options` object passed to `start`. If the
    * provided function has two arguments, the options and a callback, the app's
    * initialization will wait until you call the callback. If the callback is
    * called with a truthy first argument, an error will be logged and
    * initialization will halt. If the app has already started when you call
    * `addInitializer`, the function is called immediately.
    *
    *     app.addInitializer(function(options) {
    *         doSyncStuff();
    *     });
    *     app.addInitializer(function(options, cb) {
    *         doAsyncStuff(cb);
    *     });
    *     app.start();
    *
    * @param {Function} fn `function(options)` or `function(options, cb)`
    *     {Object} options - options passed from `start`
    *     {Function} cb - optional async callback `function(err)`
    */


    App.prototype.addInitializer = function(fn) {
      if (this.started) {
        fn.call(this, this._startOptions);
        _.extend(this, this._startOptions);
      } else {
        this._initializers.push(fn);
      }
      return this;
    };

    /*
    * Starts the app by executing each initializer in the order it was added,
    * passing `options` through the initializer queue. Triggers the `appEvents`
    * `'app:initializing'` and `'app:initialized'`.
    *
    * @param {Object} [options]
    */


    App.prototype.start = function(options) {
      var next,
        _this = this;
      if (options == null) {
        options = {};
      }
      this._startOptions = options;
      this.trigger('app:initializing', options);
      next = function(err) {
        var fn;
        if (err) {
          return error(err);
        }
        fn = _this._initializers.shift();
        if (fn) {
          if (fn.length === 2) {
            return fn.call(_this, options, next);
          } else {
            fn.call(_this, options);
            return next();
          }
        } else {
          _.extend(_this, options);
          _this.started = true;
          return _this.trigger('app:initialized', options);
        }
      };
      next();
      return this;
    };

    return App;

  })(Giraffe.View);

  /*
  * The __Giraffe.Router__ integrates with a __Giraffe.App__ to decouple your
  * router and route handlers and to provide programmatic encapsulation for your
  * routes. Routes trigger `appEvents` on the router's instance of
  * __Giraffe.App__. All __Giraffe__ objects implement the `appEvents` hash as a
  * shortcut. `Giraffe.Router#cause` triggers an app event and navigates to its
  * route if one exists in `Giraffe.Router#triggers`, and you can ask the router
  * if a given app event is currently caused via `Giraffe.Router#isCaused`.
  * Additionally, rather than building anchor links and window locations manually,
  * you can build routes from app events and optional parameters with
  * `Giraffe.Router#getRoute`.
  *
  *     var myApp = new Giraffe.App;
  *     var myRouter = Giraffe.Router.extend({
  *       triggers: {
  *         'post/:id': 'route:post'
  *       }
  *     });
  *     myRouter.app === myApp; // => true
  *     myRouter.cause('route:post', 42); // goes to `#post/42` and triggers 'route:post' on `myApp`
  *     myRouter.isCaused('route:post', 42); // => true
  *     myRouter.getRoute('route:post', 42); // => '#post/42'
  *
  * The __Giraffe.Router__ requires that a __Giraffe.App__ has been created on the
  * page so it can trigger events for your objects to listen to. For convenience,
  * if a __Giraffe.App__ is created with a `routes` hash, it will automatically
  * instantiate a router and set its `triggers` equal to the app's `routes`.
  *
  *     var myApp = Giraffe.App.extend({
  *       routes: {'my/route': 'app:event'}
  *     });
  *     myApp.router.triggers; // => {'my/route': 'app:event'}
  *
  * Like all __Giraffe__ objects, __Giraffe.Router__ extends each instance with
  * every property in `options`.
  *
  * @param {Object} [options]
  */


  Giraffe.Router = (function(_super) {
    __extends(Router, _super);

    function Router(options) {
      Giraffe.configure(this, options);
      if (!this.app) {
        return error('Giraffe routers require an app! Please create an instance of Giraffe.App before creating a router.');
      }
      this.app.addChild(this);
      if (typeof this.triggers === 'function') {
        this.triggers = this.triggers.call(this);
      }
      if (!this.triggers) {
        return error('Giraffe routers require a `triggers` map of routes to app events.');
      }
      this._routes = {};
      this._bindTriggers();
      Router.__super__.constructor.apply(this, arguments);
    }

    Router.prototype.namespace = '';

    Router.prototype._fullNamespace = function() {
      if (this.parentRouter) {
        return this.parentRouter._fullNamespace() + '/' + this.namespace;
      } else {
        return this.namespace;
      }
    };

    /*
    * The __Giraffe.Router__ `triggers` hash is similar `Backbone.Router#routes`,
    * but instead of `route: method` the __Giraffe.Router__ expects
    * `route: appEvent`. `Backbone.Router#routes` is used internally, which is why
    * `Giraffe.Router#triggers` is renamed. The router also has a redirect
    * feature as demonstrated below.
    *
    *     triggers: {
    *       'some/route/:andItsParams': 'some:appEvent', // triggers 'some:appEvent' on this.app
    *       'some/other/route': '-> some/redirect/route' // redirect
    *     }
    */


    Router.prototype.triggers = null;

    Router.prototype._bindTriggers = function() {
      var appEvent, fullNs, route, _fn, _ref,
        _this = this;
      if (!this.triggers) {
        error('Expected router to implement `triggers` hash in the form {route: appEvent}');
      }
      fullNs = this._fullNamespace();
      if (fullNs.length > 0) {
        fullNs += '/';
      }
      _ref = this.triggers;
      _fn = function(route, appEvent, fullNs) {
        var callback;
        if (appEvent.indexOf('-> ') === 0) {
          callback = function() {
            var redirect;
            redirect = appEvent.slice(3);
            return _this.navigate(redirect, {
              trigger: true
            });
          };
        } else if (appEvent.indexOf('=> ') === 0) {
          callback = function() {
            var redirect;
            redirect = appEvent.slice(3);
            return _this.navigate(fullNs + redirect, {
              trigger: true
            });
          };
        } else {
          route = fullNs + route;
          callback = function() {
            var args, _ref1;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return (_ref1 = _this.app).trigger.apply(_ref1, [appEvent].concat(__slice.call(args), [route]));
          };
          _this._registerRoute(appEvent, route);
        }
        return _this.route(route, appEvent, callback);
      };
      for (route in _ref) {
        appEvent = _ref[route];
        _fn(route, appEvent, fullNs);
      }
      return this;
    };

    Router.prototype._unbindTriggers = function() {
      var triggers;
      triggers = this._getTriggerRegExpStrings();
      return Backbone.history.handlers = _.reject(Backbone.history.handlers, function(handler) {
        return _.contains(triggers, handler.route.toString());
      });
    };

    Router.prototype._getTriggerRegExpStrings = function() {
      return _.map(_.keys(this.triggers), function(route) {
        return Backbone.Router.prototype._routeToRegExp(route).toString();
      });
    };

    /*
    * If `this.triggers` has a route that maps to `appEvent`, the router navigates
    * to the route, triggering the `appEvent`. If no such matching route exists,
    * `cause` acts as an alias for `this.app.trigger`.
    *
    * @param {String} appEvent App event name.
    * @param {Object} [any] Optional parameters.
    */


    Router.prototype.cause = function() {
      var any, appEvent, last, route, _ref;
      appEvent = arguments[0], any = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      route = this.getRoute.apply(this, [appEvent].concat(__slice.call(any)));
      if (route != null) {
        last = any[any.length - 1];
        return Backbone.history.navigate(route, _.extend({
          trigger: true
        }, (_.isObject(last) ? last : {})));
      } else {
        return (_ref = this.app).trigger.apply(_ref, [appEvent].concat(__slice.call(any)));
      }
    };

    /*
    * Returns true if the current `window.location` matches the route that the
    * given app event and optional arguments map to in this router's `triggers`.
    *
    * @param {String} appEvent App event name.
    * @param {Object} [any] Optional parameters.
    */


    Router.prototype.isCaused = function() {
      var any, appEvent, route;
      appEvent = arguments[0], any = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      route = this.getRoute.apply(this, [appEvent].concat(__slice.call(any)));
      if (route != null) {
        return this._getLocation() === route;
      } else {
        return false;
      }
    };

    Router.prototype._getLocation = function() {
      if (Backbone.history._hasPushState) {
        return window.location.pathname.slice(1);
      } else {
        return window.location.hash;
      }
    };

    /*
    * Converts an app event and optional arguments into a url mapped in
    * `this.triggers`. Useful to build links to the routes in your app without
    * manually manipulating route strings.
    *
    * @param {String} appEvent App event name.
    * @param {Object} [any] Optional parameter.
    */


    Router.prototype.getRoute = function() {
      var any, appEvent, route;
      appEvent = arguments[0], any = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      route = this._routes[appEvent];
      if (route != null) {
        route = this._reverseHash.apply(this, [route].concat(__slice.call(any)));
        if (route) {
          if (Backbone.history._hasPushState) {
            return route;
          } else {
            return '#' + route;
          }
        } else if (route === '') {
          return '';
        } else {
          return null;
        }
      } else {
        return null;
      }
    };

    Router.prototype._registerRoute = function(appEvent, route) {
      return this._routes[appEvent] = route;
    };

    Router.prototype._reverseHash = function() {
      var args, first, result, route, wildcards;
      route = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      first = args[0];
      if (first == null) {
        return route;
      }
      wildcards = /:\w+|\*\w+/g;
      if (_.isObject(first)) {
        result = route.replace(wildcards, function(token, index) {
          var key, _ref;
          key = token.slice(1);
          return (_ref = first[key]) != null ? _ref : '';
        });
      } else {
        result = route.replace(wildcards, function(token, index) {
          var value;
          value = args.shift();
          return value != null ? value : '';
        });
      }
      return result;
    };

    /*
    * Performs a page refresh. If `url` is defined, the router first silently
    * navigates to it before refeshing.
    *
    * @param {String} [url]
    */


    Router.prototype.reload = function(url) {
      if (url) {
        Backbone.history.stop();
        window.location = url;
      }
      return window.location.reload();
    };

    /*
    * See [`Giraffe.App#appEvents`](#App-appEvents).
    */


    Router.prototype.appEvents = null;

    /*
    * Removes registered callbacks.
    *
    */


    Router.prototype.beforeDispose = function() {
      return this._unbindTriggers();
    };

    return Router;

  })(Backbone.Router);

  /*
  * __Giraffe.Model__ and __Giraffe.Collection__ are thin wrappers that add
  * lifecycle management and `appEvents` support. To add lifecycle management to
  * an arbitrary object, simply give it a `dispose` method and add it to a view
  * via `addChild`. To use this functionality in your own objects, see
  * [`Giraffe.dispose`](#dispose) and [`Giraffe.bindEventMap`](#bindEventMap).
  *
  * Like all __Giraffe__ objects, __Giraffe.Model__ and __Giraffe.Collection__
  * extend each instance with every property in `options` except `parse` which
  * is problematic per issue 7.
  *
  * @param {Object} [attributes]
  * @param {Object} [options]
  */


  Giraffe.Model = (function(_super) {
    __extends(Model, _super);

    Model.defaultOptions = {
      omittedOptions: 'parse'
    };

    function Model(attributes, options) {
      Giraffe.configure(this, options);
      Model.__super__.constructor.apply(this, arguments);
    }

    /*
    * See [`Giraffe.App#appEvents`](#App-appEvents).
    */


    Model.prototype.appEvents = null;

    /*
    * Removes event listeners and removes this model from its collection.
    */


    Model.prototype.beforeDispose = function() {
      var _ref;
      this._disposed = true;
      return (_ref = this.collection) != null ? _ref.remove(this) : void 0;
    };

    return Model;

  })(Backbone.Model);

  /*
  * See [`Giraffe.Model`](#Model).
  *
  * @param {Array} [models]
  * @param {Object} [options]
  */


  Giraffe.Collection = (function(_super) {
    __extends(Collection, _super);

    Collection.defaultOptions = {
      omittedOptions: 'parse'
    };

    Collection.prototype.model = Giraffe.Model;

    function Collection(models, options) {
      Giraffe.configure(this, options);
      Collection.__super__.constructor.apply(this, arguments);
    }

    /*
    * See [`Giraffe.App#appEvents`](#App-appEvents).
    */


    Collection.prototype.appEvents = null;

    /*
    * Removes event listeners and disposes of all models, which removes them from
    * the collection.
    */


    Collection.prototype.beforeDispose = function() {
      var model, _i, _len, _ref;
      _ref = this.models.slice();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        model = _ref[_i];
        model.dispose();
      }
      return this;
    };

    Collection.prototype._removeReference = function(model) {
      Collection.__super__._removeReference.apply(this, arguments);
      if (!model._disposed) {
        return typeof model.dispose === "function" ? model.dispose() : void 0;
      }
    };

    return Collection;

  })(Backbone.Collection);

  /*
  * Initializes an object with several generic features.
  * All __Giraffe__ objects call this function in their constructors to gain much
  * of their functionality.
  * Uses duck typing to initialize features when dependencies are met.
  *
  * Features:
  *
  * - -pulls option defaults from the global `Giraffe.defaultOptions`, the static `obj.constructor.defaultOptions`, and the instance/prototype `obj.defaultOptions`
  * - -extends the object with all options minus `omittedOptions` (omits all if `true`)
  * - -defaults `obj.dispose` to `Giraffe.dispose`
  * - -defaults `obj.app` to `Giraffe.app`
  * - -binds `appEvents` if `appEvents` and `app` are defined and `obj` extends `Backbone.Events`
  * - -binds `dataEvents` if `dataEvents` is defined and `obj` extends `Backbone.Events`
  * - -wraps `initialize` with `beforeInitialize` and `afterInitialize` if it exists
  *
  * @param {Object} obj Any object.
  * @param {Obj} [opts] Extended along with `defaultOptions` onto `obj` minus `options.omittedOptions`. If `options.omittedOptions` is true, all are omitted.
  */


  Giraffe.configure = function(obj, opts) {
    var omittedOptions, options, _ref, _ref1;
    if (!obj) {
      error("Cannot configure obj", obj);
      return false;
    }
    options = _.extend({}, Giraffe.defaultOptions, (_ref = obj.constructor) != null ? _ref.defaultOptions : void 0, obj.defaultOptions, opts);
    omittedOptions = (_ref1 = options.omittedOptions) != null ? _ref1 : obj.omittedOptions;
    if (omittedOptions !== true) {
      _.extend(obj, _.omit(options, omittedOptions));
    }
    if (obj.dispose == null) {
      obj.dispose = Giraffe.dispose;
    }
    if (obj.app == null) {
      obj.app = Giraffe.app;
    }
    if (obj.appEvents) {
      Giraffe.bindAppEvents(obj);
    }
    if (obj.initialize) {
      Giraffe.wrapFn(obj, 'initialize', null, _afterInitialize);
    } else {
      _afterInitialize.call(obj);
    }
    return obj;
  };

  /*
  * The global defaults extended to every object passed to `Giraffe.configure`.
  * Empty by default.
  * Setting `omittedOptions` here globally prevents those properties from being
  * copied over, and if its value is `true` extension is completely disabled.
  *
  *     function Foo() {
  *       Giraffe.configure(this);
  *     };
  *     Giraffe.defaultOptions = {bar: 'global'};
  *     var foo = new Foo();
  *     foo.bar; // => 'global'
  *
  * You can also define `defaultOptions` on a function constructor.
  * These override the global defaults.
  *
  *     Foo.defaultOptions = {bar: 'constructor'};
  *     foo = new Foo();
  *     foo.bar; // => 'constructor'
  *
  * The instance/prototype defaults take even higher precedence:
  *
  *     Foo.prototype.defaultOptions = {bar: 'instance/prototype'};
  *     foo = new Foo();
  *     foo.bar; // => 'instance/prototype'
  *
  * Options passed as arguments always override `defaultOptions`.
  *
  *     foo = new Foo({bar: 'option'});
  *     foo.bar; // => 'option'
  *
  * Be aware that the values of all `defaultOptions` are not cloned when copied over.
  *
  * @caption Giraffe.defaultOptions
  */


  Giraffe.defaultOptions = {};

  _afterInitialize = function() {
    if (this.dataEvents) {
      return Giraffe.bindDataEvents(this);
    }
  };

  /*
  * Disposes of an object, removing event listeners and freeing resources.
  * An instance method of `dispose` is added for
  * all objects passed through `Giraffe.configure`, and so you will normally
  * call `dispose` directly on your objects.
  *
  * Calls `Backbone.Events#stopListening` and sets
  * `obj.app` to null. Also triggers the `'disposing'` and `'disposed'` events
  * and calls the `beforeDispose` and `afterDispose` methods on `obj` before and
  * after the disposal. Takes optional `args` that are passed through to the
  * events and the function calls.
  *
  * @param {Any} [args...] A list of arguments to by passed to the `fn` and disposal events.
  */


  Giraffe.dispose = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (typeof this.trigger === "function") {
      this.trigger.apply(this, ['disposing', this].concat(__slice.call(args)));
    }
    if (typeof this.beforeDispose === "function") {
      this.beforeDispose.apply(this, args);
    }
    this.app = null;
    if (typeof this.stopListening === "function") {
      this.stopListening();
    }
    if (typeof this.trigger === "function") {
      this.trigger.apply(this, ['disposed', this].concat(__slice.call(args)));
    }
    if (typeof this.afterDispose === "function") {
      this.afterDispose.apply(this, args);
    }
    return this;
  };

  /*
  * Attempts to bind `appEvents` for an object. Called by `Giraffe.configure`.
  */


  Giraffe.bindAppEvents = function(obj) {
    return Giraffe.bindEventMap(obj, obj.app, obj.appEvents);
  };

  /*
  * Binds the `dataEvents` hash that allows any instance property of `obj` to
  * be bound to easily. Expects the form {'event1 event2 targetObj': 'handler'}.
  * Called by `Giraffe.configure`.
  */


  Giraffe.bindDataEvents = function(obj) {
    var cb, dataEvents, eventKey, eventName, pieces, targetObj;
    dataEvents = obj.dataEvents;
    if (!dataEvents) {
      return;
    }
    if (typeof dataEvents === 'function') {
      dataEvents = obj.dataEvents();
    }
    for (eventKey in dataEvents) {
      cb = dataEvents[eventKey];
      pieces = eventKey.split(' ');
      if (pieces.length < 2) {
        error('Data event must specify target object, ex: {\'change collection\': \'handler\'}');
        continue;
      }
      targetObj = pieces.pop();
      targetObj = targetObj === 'this' || targetObj === '@' ? obj : obj[targetObj];
      if (!targetObj) {
        error("Target object not found for data event '" + eventKey + "'", obj);
        continue;
      }
      eventName = pieces.join(' ');
      Giraffe.bindEvent(obj, targetObj, eventName, cb);
    }
    return obj;
  };

  /*
  * Uses `Backbone.Events.listenTo` to make `contextObj` listen for `eventName` on
  * `targetObj` with the callback `cb`, which can be a function or the string name
  * of a method on `contextObj`.
  *
  * @param {Backbone.Events} contextObj The object doing the listening.
  * @param {Backbone.Events} targetObj The object to listen to.
  * @param {String/Function} eventName The name of the event to listen to.
  * @param {Function} cb The event's callback.
  */


  Giraffe.bindEvent = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    args.push('listenTo');
    return _setEventBindings.apply(null, args);
  };

  /*
  * The `stopListening` equivalent of `bindEvent`.
  *
  * @param {Backbone.Events} contextObj The object doing the listening.
  * @param {Backbone.Events} targetObj The object to listen to.
  * @param {String/Function} eventName The name of the event to listen to.
  * @param {Function} cb The event's callback.
  */


  Giraffe.unbindEvent = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    args.push('stopListening');
    return _setEventBindings.apply(null, args);
  };

  /*
  * Makes `contextObj` listen to `targetObj` for the events of `eventMap` in the
  * form `eventName: method`, where `method` is a function or the name of a
  * function on `contextObj`.
  *
  *     Giraffe.bindEventMap(this, this.app, this.appEvents);
  *
  * @param {Backbone.Events} contextObj The object doing the listening.
  * @param {Backbone.Events} targetObj The object to listen to.
  * @param {Object} eventMap A map of events to callbacks in the form {eventName: methodName/methodFn} to listen to.
  */


  Giraffe.bindEventMap = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    args.push('listenTo');
    return _setEventMapBindings.apply(null, args);
  };

  /*
  * The `stopListening` equivalent of `bindEventMap`.
  *
  * @param {Backbone.Events} contextObj The object doing the listening.
  * @param {Backbone.Events} targetObj The object to listen to.
  * @param {Object} eventMap A map of events to callbacks in the form {eventName: methodName/methodFn} to listen to.
  */


  Giraffe.unbindEventMap = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    args.push('stopListening');
    return _setEventMapBindings.apply(null, args);
  };

  _setEventBindings = function(contextObj, targetObj, eventName, cb, bindOrUnbindFnName) {
    if (typeof cb === 'string') {
      cb = contextObj[cb];
    }
    if (typeof cb !== 'function') {
      error("callback for `'" + eventName + "'` not found", contextObj, targetObj, cb);
      return;
    }
    return contextObj[bindOrUnbindFnName](targetObj, eventName, cb);
  };

  _setEventMapBindings = function(contextObj, targetObj, eventMap, bindOrUnbindFnName) {
    var cb, eventName;
    if (typeof eventMap === 'function') {
      eventMap = eventMap.call(contextObj);
    }
    if (!eventMap) {
      return;
    }
    for (eventName in eventMap) {
      cb = eventMap[eventName];
      _setEventBindings(contextObj, targetObj, eventName, cb, bindOrUnbindFnName);
    }
    return contextObj;
  };

  /*
  * Wraps `obj[fnName]` with `beforeFnName` and `afterFnName` invocations. Also
  * calls the optional arguments `beforeFn` and `afterFn`.
  *
  * @param {Object} obj
  * @param {String} fnName
  * @param {Function} [beforeFn]
  * @param {Function} [afterFn]
  */


  Giraffe.wrapFn = function(obj, fnName, beforeFn, afterFn) {
    var capFnName, fn;
    fn = obj[fnName];
    if (typeof fn !== 'function') {
      return;
    }
    capFnName = fnName[0].toUpperCase() + fnName.slice(1);
    return obj[fnName] = function() {
      var args, result, _name, _name1;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (beforeFn != null) {
        beforeFn.apply(obj, args);
      }
      if (typeof obj[_name = 'before' + capFnName] === "function") {
        obj[_name].apply(obj, args);
      }
      result = fn.apply(obj, args);
      if (typeof obj[_name1 = 'after' + capFnName] === "function") {
        obj[_name1].apply(obj, args);
      }
      if (afterFn != null) {
        afterFn.apply(obj, args);
      }
      return result;
    };
  };

  if (_.isObject(typeof module !== "undefined" && module !== null ? module.exports : void 0)) {
    module.exports = Giraffe;
  } else if (typeof define === 'function' && define.amd) {
    define('backbone.giraffe', [], function() {
      return Giraffe;
    });
  }

}).call(this);
