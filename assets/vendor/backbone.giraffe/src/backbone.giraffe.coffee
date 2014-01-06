#===============================================================================
# Copyright (c) 2013 Barc Inc.
#
# Barc Permissive License
#===============================================================================


{$, _, Backbone} = window


Backbone.Giraffe = window.Giraffe = Giraffe =
  version: '{{VERSION}}'
  app: null # stores the most recently created instance of App, so for simple cases with 1 app Giraffe objects don't need an app reference
  apps: {} # cache for all app views by `cid`
  views: {} # cache for all views by `cid`


$window = $(window)
$document = $(document)


# A helper function for more helpful error messages.
error = ->
  console?.error?.apply console, ['Backbone.Giraffe error:'].concat(arguments...)


###
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
###
class Giraffe.View extends Backbone.View


  @defaultOptions:
    disposeOnDetach: true       # If true, disposes of the view when detached from the DOM.
    # alwaysRender: false       # If true, always renders on attach unless suppressRender is passed as an option.
    # saveScrollPosition: false # If true or a selector, saves the scroll position of `@$el` or `@$(selector)`, respectively, when detached to be automatically applied when reattached. Object selectors aren't scoped to the view, so `window` and `$('body')` are valid values.
    # documentTitle: null       # When the view is attached, the document.title will be set to this.


  constructor: (options) ->
    Giraffe.configure @, options

    ###
    * When one view is attached to another, the child view is added to the
    * parent's `children` array. When `dispose` is called on a view, it disposes
    * of all `children`, enabling the teardown of a single view or an entire app
    * with one method call. Any object with a `dispose` method can be added
    * to a view's `children` via `addChild` to take advantage of lifecycle
    * management.
    ###
    @children = []

    ###
    * Child views attached via `attachTo` have a reference to their parent view.
    ###
    @parent = null

    @_renderedOnce = false
    @_isAttached = false

    @_createEventsFromUIElements()

    if typeof @templateStrategy is 'string'
      Giraffe.View.setTemplateStrategy @templateStrategy, @

    super


  # Pre-initialization to set `data-view-cid` is necessary to allow views to be attached in `initialize`.
  beforeInitialize: ->
    # Add the view to the global cache now that the view has a cid.
    @_cache()

    # Set the data-view-cid attribute to link dom els to their view objects.
    @$el.attr 'data-view-cid', @cid

    # Set the initial parent -- needed only in cases where an existing `el` is given to the view.
    @setParent Giraffe.View.getClosestView(@$el)

    # Cache any elements that might already be in `el`
    @_cacheUiElements()


  _attachMethods: ['append', 'prepend', 'html', 'after', 'before', 'insertAfter', 'insertBefore']
  _siblingAttachMethods: ['after', 'before', 'insertAfter', 'insertBefore']


  ###
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
  ###
  attachTo: (el, options) ->
    method = options?.method or 'append'
    forceRender = options?.forceRender or false
    suppressRender = options?.suppressRender or false

    if !@$el
      error 'Trying to attach a disposed view. Make a new one or create the view with the option `disposeOnDetach` set to false.', @
      return @

    if !_.contains(@_attachMethods, method)
      error "The attach method '#{method}' isn't supported. Defaulting to 'append'.", method, @_attachMethods
      method = 'append'

    $el = Giraffe.View.to$El(el)

    # Make sure we're attaching to a single element
    if $el.length isnt 1
      error('Expected to render to a single element but found ' + $el.length, el)
      return @

    @trigger 'attaching', @, $el, options

    # $el and $container differ for jQuery methods that operate on siblings
    $container = if _.contains(@_siblingAttachMethods, method) then $el.parent() else $el

    # The methods 'insertAfter' and 'insertBefore' become 'after' and 'before' because we always call $el[method] @$el
    method = 'after' if method is 'insertAfter'
    method = 'before' if method is 'insertBefore'

    # Detach the view so it can move around freely, preserving it so it's not disposed.
    @detach true

    # Set the new parent.
    @setParent Giraffe.View.getClosestView($container)

    # If the method is destructive, detach any children of the parent to prevent event clobbering.
    if method is 'html'
      Giraffe.View.detachByEl $el
      $el.empty()

    # Attach the view to the el.
    $el[method] @$el
    @_isAttached = true

    # Render as necessary.
    shouldRender = !suppressRender and (!@_renderedOnce or forceRender or @alwaysRender)
    if shouldRender
      @render options

    @_loadScrollPosition() if @saveScrollPosition
    document.title = @documentTitle if @documentTitle?
    @trigger 'attached', @, $el, options
    @


  ###
  * `attach` is an inverted way to call `attachTo`. Unlike `attachTo`, calling
  * this function requires a parent view. It's here only for aesthetics. Takes
  * the same `options` as `attachTo` in addition to the optional `options.el`,
  * which is the first argument passed to `attachTo`, defaulting to the parent
  * view.
  *
  * @param {View} view
  * @param {Object} [options]
  * @caption parentView.attach(childView, [options])
  ###
  attach: (view, options) ->
    target = null
    if options?.el
      childEl = Giraffe.View.to$El(options.el, @$el, true)
      if childEl.length
        target = childEl
      else
        error 'Attempting to attach to an element that doesn\'t exist inside this view!', options, view, @
        return @
    else
      target = @$el
    view.attachTo target, options
    @


  ###
  * __Giraffe__ implements `render` so it can do some helpful things, but you can
  * still call it like you normally would. By default, `render` uses a view's
  * `template`, which is the DOM selector of an __Underscore__ template, but
  * this is easily configured. See [`Giraffe.View#template`](#View-template),
  * [`Giraffe.View.setTemplateStrategy`](#View-setTemplateStrategy), and
  * [`Giraffe.View#templateStrategy`](#View-templateStrategy) for more.
  *
  * @caption Do not override unless you know what you're doing!
  ###
  render: (options) =>
    @trigger 'rendering', @, options
    @beforeRender.apply @, arguments
    @_renderedOnce = true
    @detachChildren options?.preserve
    html = @templateStrategy.apply(@, arguments) or ''
    @$el.empty()[0].innerHTML = html
    @_cacheUiElements()
    @afterRender.apply @, arguments
    @trigger 'rendered', @, options
    @


  ###
  * This is an empty function for you to implement. Less commonly used than
  * `afterRender`, but helpful in circumstances where the DOM has state that
  * needs to be preserved across renders. For example, if a view with a dropdown
  * menu is rendering, you may want to save its open state in `beforeRender`
  * and reapply it in `afterRender`.
  *
  * @caption Implement this function in your views.
  ###
  beforeRender: ->


  ###
  * This is an empty function for you to implement. After a view renders,
  * `afterRender` is called. Child views are normally attached to the DOM here.
  * Views that are cached by setting `disposeOnDetach` to true will be
  * in `view.children` in `afterRender`, but will not be attached to the
  * parent's `$el`.
  *
  * @caption Implement this function in your views.
  ###
  afterRender: ->


  ###
  * __Giraffe__ implements its own `render` function which calls `templateStrategy`
  * to get the HTML string to put inside `view.$el`. Your views can either
  * define a `template`, which uses __Underscore__ templates by default and is
  * customizable via [`Giraffe.View#setTemplateStrategy`](#View-setTemplateStrategy),
  * or override `templateStrategy` with a function returning a string of HTML
  * from your favorite templating engine. See the
  * [_Template Strategies_ example](templateStrategies.html) for more.
  ###
  templateStrategy: -> ''


  ###
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
  ###
  template: null


  ###
  * Gets the data passed to the `template`. Returns the view by default.
  *
  * @caption Override this function to pass custom data to a view's `template`.
  ###
  serialize: -> @


  ###
  * Detaches the view from the DOM. If `view.disposeOnDetach` is true,
  * which is the default, `dispose` will be called on the view and its
  * `children` unless `preserve` is true. `preserve` defaults to false. When
  * a view renders, it first calls `detach(false)` on the views inside its `$el`.
  *
  * @param {Boolean} [preserve] If true, doesn't dispose of the view, even if `disposeOnDetach` is `true`.
  ###
  detach: (preserve = false) ->
    return @ unless @_isAttached
    @_isAttached = false

    @_saveScrollPosition() if @saveScrollPosition

    # Detaches the view from the DOM, keeping its DOM event bindings intact.
    @trigger 'detaching', @, preserve
    @$el.detach()
    @trigger 'detached', @, preserve

    # Disposes the view unless the view's options or function caller preserve it.
    @dispose() if @disposeOnDetach and !preserve
    @


  ###
  * Calls `detach` on each object in `children`, passing `preserve` through.
  *
  * @param {Boolean} [preserve]
  ###
  detachChildren: (preserve = false) ->
    child.detach? preserve for child in @children.slice() # slice because @children may be modified
    @


  _saveScrollPosition: ->
    @_scrollPosition = @_getScrollPositionEl().scrollTop()
    @


  _loadScrollPosition: ->
    if @_scrollPosition?
      @_getScrollPositionEl().scrollTop @_scrollPosition
    @


  _getScrollPositionEl: ->
    if typeof @saveScrollPosition is 'boolean' or @$el.is(@saveScrollPosition)
      @$el
    else
      # First search for an $el scoped to this view, then search globally
      $el = Giraffe.View.to$El(@saveScrollPosition, @$el).first()
      if $el.length
        $el
      else
        $el = Giraffe.View.to$El(@saveScrollPosition).first()
        if $el.length
          $el
        else
          @$el


  ###
  * Adds `child` to this view's `children` and assigns this view as
  * `child.parent`. If `child` implements `dispose`, it will be called when the
  * view is disposed. If `child` implements `detach`, it will be called before
  * the view renders.
  *
  * @param {Object} child
  ###
  addChild: (child) ->
    if !_.contains(@children, child)
      child.parent?.removeChild child, true
      child.parent = @
      @children.push child
    @


  ###
  * Calls `addChild` on the given array of objects.
  *
  * @param {Array} children Array of objects
  ###
  addChildren: (children) ->
    @addChild child for child in children
    @


  ###
  * Removes an object from this view's `children`. If `preserve` is `false`, the
  * default, __Giraffe__ will attempt to call `dispose` on the child. If
  * `preserve` is true, __Giraffe__ will attempt to call `detach(true)` on the
  * child.
  *
  * @param {Object} child
  * @param {Boolean} [preserve] If `true`, Giraffe attempts to call `detach` on the child, otherwise it attempts to call `dispose` on the child. Is `false` by default.
  ###
  removeChild: (child, preserve = false) ->
    index = _.indexOf(@children, child)
    if index isnt -1
      @children.splice index, 1
      child.parent = null
      if preserve
        child.detach? true
      else
        child.dispose?()
    @


  ###
  * Calls `removeChild` on all `children`, passing `preserve` through.
  *
  * @param {Boolean} [preserve] If `true`, detaches rather than removes the children.
  ###
  removeChildren: (preserve = false) ->
    @removeChild child, preserve for child in @children.slice() # slice because @children is modified
    @


  ###
  * Sets a new parent for a view, first removing any current parent-child
  * relationship. `parent` can be falsy to remove the current parent.
  *
  * @param {Giraffe.View} [parent]
  ###
  setParent: (parent) ->
    if parent and parent isnt @
      parent.addChild @
    else if @parent
      @parent.removeChild @, true
      @parent = null
    @


  ###
  * If `el` is `null` or `undefined`, tests if the view is somewhere on the DOM
  * by calling `$document.find(view.$el)`. If `el` is a view, tests if `el` contains
  * this view. Otherwise, tests if `el` is the immediate parent of `view.$el`.
  *
  * @param {String} [el] Optional selector, DOM element, or view to test against the view's immediate parent.
  * @returns {Boolean}
  ###
  isAttached: (el) ->
    if el?
      if el.$el
        !!el.$el.find(@$el).length
      else
        @$el.parent().is(el)
    else
      !!$document.find(@$el).length


  ###
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
  ###
  ui: null


  # Caches jQuery objects to the view, reading the map @ui {name: selector}, made available as @name.
  _cacheUiElements: ->
    if @ui
      for name, selector of @ui
        @[name] = switch typeof selector
          when 'string'
            @$(selector)
          when 'function'
            selector.call @
          else
            selector
    @


  # Removes references to the elements cached from the @ui {name: selector} map..
  _uncacheUiElements: ->
    if @ui
      for name of @ui
        delete @[name]
    @


  # Inserts the `ui` names into `events`.
  _createEventsFromUIElements: ->
    return @ unless @events and @ui
    @ui = @ui.call(@) if typeof @ui is 'function'
    @events = @events.call(@) if typeof @events is 'function'
    for eventKey, method of @events
      newEventKey = @_getEventKeyFromUIElements(eventKey)
      if newEventKey isnt eventKey
        delete @events[eventKey]
        @events[newEventKey] = method
    @


  # Creates an `events` key that replaces any `ui` names with their selectors.
  _getEventKeyFromUIElements: (eventKey) ->
    parts = eventKey.split(' ')
    length = parts.length
    return eventKey if length < 2
    lastPart = parts[length - 1]
    uiTarget = @ui[lastPart]
    if uiTarget
      parts[length - 1] = uiTarget
      parts.join ' '
    else
      eventKey


  ###
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
  ###
  dataEvents: null


  # Removes the view from the global cache.
  _uncache: ->
    delete Giraffe.views[@cid]
    @


  # Stores the view in the global cache.
  _cache: ->
    Giraffe.views[@cid] = @
    @


  ###
  * Calls `methodName` on the view, or if not found, up the view hierarchy until
  * it either finds the method or fails on a view without a `parent`. Used by
  * __Giraffe__ to call the methods defined for the events bound in
  * `Giraffe.View.setDocumentEvents`.
  *
  * @param {String} methodName
  * @param {Any} [args...]
  ###
  invoke: (methodName, args...) ->
    view = @
    while view and !view[methodName]
      view = view.parent
    if view?[methodName]
      view[methodName].apply view, args
    else
      error 'No such method name in view hierarchy', methodName, args, @
      false


  ###
  * See [`Giraffe.App#appEvents`](#App-appEvents).
  ###
  appEvents: null


  ###
  * Destroys a view, unbinding its events and freeing its resources. Calls
  * `Backbone.View#remove` and calls `dispose` on all `children`.
  ###
  beforeDispose: ->
    @setParent null
    @removeChildren()
    @_uncacheUiElements()
    @_uncache()
    @_isAttached = false
    if @$el
      @remove()
      @$el = null
    else
      error 'Disposed of a view that has already been disposed', @
    @


  ###
  * Detaches the top-level views inside `el`, which can be a selector, element,
  * or __Giraffe.View__. Used internally by __Giraffe__ to remove views that
  * would otherwise be clobbered when the option `method: 'html'` is used
  * in `attachTo`. Uses the `data-view-cid` attribute to match DOM nodes to view
  * instances.
  *
  * @param {String/Element/$/Giraffe.View} el
  * @param {Boolean} [preserve]
  ###
  @detachByEl: (el, preserve = false) ->
    $el = Giraffe.View.to$El(el)
    while ($child = $el.find('[data-view-cid]:first')).length
      cid = $child.attr('data-view-cid')
      view = Giraffe.View.getByCid(cid)
      view.detach preserve
    @


  ###
  * Gets the closest parent view of `el`, which can be a selector, element, or
  * __Giraffe.View__. Uses the `data-view-cid` attribute to match DOM nodes to
  * view instances.
  *
  * @param {String/Element/$/Giraffe.View} el
  ###
  @getClosestView: (el) ->
    $el = Giraffe.View.to$El(el)
    cid = $el.closest('[data-view-cid]').attr('data-view-cid')
    Giraffe.View.getByCid cid


  ###
  * Looks up a view from the cache by `cid`, returning undefined if not found.
  *
  * @param {String} cid
  ###
  @getByCid: (cid) ->
    Giraffe.views[cid]


  ###
  * Gets a __jQuery__ object from `el`, which can be a selector, element,
  * __jQuery__ object, or __Giraffe.View__, scoped by an optional `parent`,
  * which has the same available types as `el`. If the third parameter is
  * truthy, `el` can be the same element as `parent`.
  *
  * @param {String/Element/$/Giraffe.View} el
  * @param {String/Element/$/Giraffe.View} [parent] Opitional. Scopes `el` if provided.
  * @param {Boolean} [allowParentMatch] Optional. If truthy, `el` can be `parent`.
  ###
  @to$El: (el, parent, allowParentMatch = false) ->
    if parent
      $parent = Giraffe.View.to$El(parent)
      el = el.$el if el?.$el
      if allowParentMatch and $parent.is(el)
        $parent
      else
        $parent.find(el)
    else if el?.$el
      el.$el
    else if el instanceof $
      el
    else
      $(el)


  ###
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
  ###
  @setDocumentEvents: (events, prefix = Giraffe.View._documentEventPrefix) ->
    prefix = prefix or ''
    if typeof events is 'string'
      events = events.split(' ')
    if !_.isArray(events)
      events = [events]
    events = _.compact(events)

    Giraffe.View.removeDocumentEvents()
    Giraffe.View._currentDocumentEvents = events
    Giraffe.View._documentEventPrefix = prefix

    for event in events
      attr = prefix + event
      selector = '[' + attr + ']'
      do (event, attr, selector) ->
        $document.on event, selector, (e) ->
          $target = $(e.target).closest(selector)
          method = $target.attr(attr)
          view = Giraffe.View.getClosestView($target)
          view.invoke method, e

    events


  ###
  * Equivalent to `Giraffe.View.setDocumentEvents(null)`.
  ###
  @removeDocumentEvents: (prefix = Giraffe.View._documentEventPrefix) ->
    prefix = prefix or ''
    currentEvents = Giraffe.View._currentDocumentEvents
    return unless currentEvents?.length
    for event in currentEvents
      selector = '[' + prefix + event + ']'
      $document.off event, selector
    Giraffe.View._currentDocumentEvents = null


  ###
  * Sets the prefix for document events. Defaults to `data-gf-`,
  * so to bind to `'click'` events, one would put the `data-gf-click`
  * attribute on DOM elements with the name of a view method as the value.
  *
  * @param {String} prefix If `null` or `undefined`, defaults to the empty string.
  ###
  @setDocumentEventPrefix: (prefix = '') ->
    Giraffe.View.setDocumentEvents Giraffe.View._currentDocumentEvents, prefix


  ###
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
  ###
  @setTemplateStrategy: (strategy, instance) ->

    strategyType = typeof strategy
    if strategyType is 'function'
      templateStrategy = strategy
    else if strategyType isnt 'string'
      return error('Unrecognized template strategy', strategy)
    else
      switch strategy.toLowerCase()

        # @template is a string DOM selector or a function returning DOM selector
        when 'underscore-template-selector'
          templateStrategy = ->
            return '' unless @template
            if !@_templateFn
              switch typeof @template
                when 'string'
                  selector = @template
                  @_templateFn = _.template($(selector).html() or '')
                when 'function'
                  # user likely made it a function because it depends on
                  # run time info, ensure it is called EACH time
                  @_templateFn = (locals) =>
                    selector = @template()
                    _.template $(selector).html() or '', locals
                else
                  throw new Error('this.template must be string or function')

            @_templateFn @serialize.apply(@, arguments)

        # @template is a string or a function returning a string template
        when 'underscore-template'
          templateStrategy = ->
            return '' unless @template
            if !@_templateFn
              switch typeof @template
                when 'string'
                  @_templateFn = _.template(@template)
                when 'function'
                  @_templateFn = (locals) =>
                    _.template @template(), locals
                else
                  throw new Error('this.template must be string or function')
            @_templateFn @serialize.apply(@, arguments)

        # @template is the markup or a JST function
        when 'jst'
          templateStrategy = ->
            return '' unless @template
            if !@_templateFn
              switch typeof @template
                when 'string'
                  html = @template
                  @_templateFn = -> html
                when 'function'
                  @_templateFn = @template
                else
                  throw new Error('this.template must be string or function')
            @_templateFn @serialize.apply(@, arguments)

        else
          throw new Error('Unrecognized template strategy: ' + strategy)

    if instance
      instance.templateStrategy = templateStrategy
    else
      Giraffe.View::templateStrategy = templateStrategy


# Initialize the default template strategy
Giraffe.View.setTemplateStrategy 'underscore-template-selector'


# Initialize the default document events
Giraffe.View.setDocumentEvents ['click', 'change'], 'data-gf-' # TODO consider a breaking change to default to 'data-on'



###
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
###
class Giraffe.App extends Giraffe.View


  constructor: (options) ->
    @app = @
    @_initializers = []
    @started = false
    super


  _cache: ->
    Giraffe.app ?= @ # for convenience, store the first created app as a global
    Giraffe.apps[@cid] = @
    if @routes
      @router ?= new Giraffe.Router(app: @, triggers: @routes)
    $window.on 'unload', @_onUnload
    super


  _uncache: ->
    Giraffe.app = null if Giraffe.app is @
    delete Giraffe.apps[@cid]
    @router = null if @router
    $window.off 'unload', @_onUnload
    super


  _onUnload: =>
    @dispose()


  ###
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
  ###
  appEvents: null


  ###
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
  ###
  routes: null


  ###
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
  ###
  addInitializer: (fn) ->
    if @started
      fn.call @, @_startOptions
      _.extend @, @_startOptions
    else
      @_initializers.push fn
    @


  ###
  * Starts the app by executing each initializer in the order it was added,
  * passing `options` through the initializer queue. Triggers the `appEvents`
  * `'app:initializing'` and `'app:initialized'`.
  *
  * @param {Object} [options]
  ###
  start: (options = {}) ->
    @_startOptions = options
    @trigger 'app:initializing', options

    # Runs all sync/async initializers.
    next = (err) =>
      return error(err) if err

      fn = @_initializers.shift()
      if fn
        # Allows asynchronous calls
        if fn.length is 2
          fn.call @, options, next
        else
          fn.call @, options
          next()
      else
        _.extend @, options
        @started = true
        @trigger 'app:initialized', options

    next()
    @



###
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
###
class Giraffe.Router extends Backbone.Router


  # Creates an instance of a Router.
  constructor: (options) ->
    Giraffe.configure @, options

    if !@app
      return error 'Giraffe routers require an app! Please create an instance of Giraffe.App before creating a router.'
    @app.addChild @ # disposes of the router when its app is removed

    @triggers = @triggers.call(@) if typeof @triggers is 'function'
    if !@triggers
      return error 'Giraffe routers require a `triggers` map of routes to app events.'

    @_routes = {}

    @_bindTriggers()
    super


  namespace: ''


  # Computes the full namespace.
  _fullNamespace: ->
    if @parentRouter
      @parentRouter._fullNamespace() + '/' + @namespace
    else
      @namespace


  ###
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
  ###
  triggers: null


  # Binds events from `triggers` property as well as setting up routes.
  #
  # triggers:
  #   'route/path': 'event:name'
  #   'route/path2': '-> absolute/path'
  #   'relativeRedirect': '=> route/path'
  _bindTriggers: ->
    if !@triggers
      error 'Expected router to implement `triggers` hash in the form {route: appEvent}'

    fullNs = @_fullNamespace()
    if fullNs.length > 0
      fullNs += '/'

    for route, appEvent of @triggers

      do (route, appEvent, fullNs) =>
        # Redirects to an absolute route
        if appEvent.indexOf('-> ') is 0
          callback = =>
            redirect = appEvent.slice(3)
            # console.log 'REDIRECTING ', appEvent, ' -> ', redirect
            @navigate redirect, trigger: true

        # Redirects to a route within this router
        else if appEvent.indexOf('=> ') is 0
          callback = =>
            redirect = appEvent.slice(3)
            # console.log 'REDIRECTING ', appEvent, ' => ', redirect
            @navigate fullNs + redirect, trigger: true

        # Triggers an appEvent on the app
        else
          route = fullNs + route
          callback = (args...) =>
            # console.log 'TRIGGERING ', appEvent
            @app.trigger appEvent, args..., route

          # register the route so we can do a reverse map
          @_registerRoute appEvent, route

        @route route, appEvent, callback
    @


  # Unbinds all triggers registered to Backbone.history
  _unbindTriggers: ->
    triggers = @_getTriggerRegExpStrings()
    Backbone.history.handlers = _.reject Backbone.history.handlers, (handler) ->
      _.contains triggers, handler.route.toString()


  # Gets the routes of `triggers` as RegExps turned to strings, the `route` of Backbone.history
  _getTriggerRegExpStrings: ->
    _.map _.keys(@triggers), (route) ->
      Backbone.Router::_routeToRegExp(route).toString()


  ###
  * If `this.triggers` has a route that maps to `appEvent`, the router navigates
  * to the route, triggering the `appEvent`. If no such matching route exists,
  * `cause` acts as an alias for `this.app.trigger`.
  *
  * @param {String} appEvent App event name.
  * @param {Object} [any] Optional parameters.
  ###
  cause: (appEvent, any...) ->
    route = @getRoute(appEvent, any...)
    if route?
      Backbone.history.navigate route, trigger: true
    else
      @app.trigger appEvent, any...


  ###
  * Returns true if the current `window.location` matches the route that the
  * given app event and optional arguments map to in this router's `triggers`.
  *
  * @param {String} appEvent App event name.
  * @param {Object} [any] Optional parameters.
  ###
  isCaused: (appEvent, any...) ->
    route = @getRoute(appEvent, any...)
    if route?
      @_getLocation() is route
    else
      false
  
  # Returns the current location
  _getLocation : ->
    if Backbone.history._hasPushState
      window.location.pathname.slice(1)
    else
      window.location.hash

  ###
  * Converts an app event and optional arguments into a url mapped in
  * `this.triggers`. Useful to build links to the routes in your app without
  * manually manipulating route strings.
  *
  * @param {String} appEvent App event name.
  * @param {Object} [any] Optional parameter.
  ###
  getRoute: (appEvent, any...) ->
    route = @_routes[appEvent]
    if route?
      route = @_reverseHash(route, any...)
      if route
        if Backbone.history._hasPushState
          route
        else
          '#' + route
      else if route is ''
        ''
      else
        null
    else
      null


  # Register a route for reverse hash mapping when `event` is invoked.
  _registerRoute: (appEvent, route) ->
    @_routes[appEvent] = route


  # Reverse map a route using `any` value.
  _reverseHash: (route, args...) ->
    first = args[0]
    return route unless first?

    wildcards = /:\w+|\*\w+/g
    if _.isObject(first)
      result = route.replace wildcards, (token, index) ->
        key = token.slice(1)
        first[key] || ''
    else
      result = route.replace wildcards, (token, index) ->
        args.shift() || ''

    result


  ###
  * Performs a page refresh. If `url` is defined, the router first silently
  * navigates to it before refeshing.
  *
  * @param {String} [url]
  ###
  reload: (url) ->
    if url
      Backbone.history.stop()
      window.location = url
    window.location.reload()


  ###
  * See [`Giraffe.App#appEvents`](#App-appEvents).
  ###
  appEvents: null


  ###
  * Removes registered callbacks.
  *
  ###
  beforeDispose: ->
    @_unbindTriggers()



###
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
###
class Giraffe.Model extends Backbone.Model


  @defaultOptions:
    omittedOptions: 'parse'


  constructor: (attributes, options) ->
    Giraffe.configure @, options
    super


  ###
  * See [`Giraffe.App#appEvents`](#App-appEvents).
  ###
  appEvents: null


  ###
  * Removes event listeners and removes this model from its collection.
  ###
  beforeDispose: ->
    @_disposed = true
    @collection?.remove @



###
* See [`Giraffe.Model`](#Model).
*
* @param {Array} [models]
* @param {Object} [options]
###
class Giraffe.Collection extends Backbone.Collection


  @defaultOptions:
    omittedOptions: 'parse'


  model: Giraffe.Model


  constructor: (models, options) ->
    Giraffe.configure @, options
    super


  ###
  * See [`Giraffe.App#appEvents`](#App-appEvents).
  ###
  appEvents: null


  ###
  * Removes event listeners and disposes of all models, which removes them from
  * the collection.
  ###
  beforeDispose: ->
    model.dispose() for model in @models.slice() # slice because `@models` is modified
    @


  # Fixes disposal problem detailed here: https://github.com/barc/backbone.giraffe/issues/20
  _removeReference: (model) ->
    super
    model.dispose?() if !model._disposed



###
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
###
Giraffe.configure = (obj, opts) ->
  if !obj
    error "Cannot configure obj", obj
    return false

  options = _.extend {},
    Giraffe.defaultOptions,
    obj.constructor?.defaultOptions,
    obj.defaultOptions,
    opts

  # Extend the object with `options` minus `omittedProperties` unless `omittedOptions` is `true`.
  omittedOptions = options.omittedOptions ? obj.omittedOptions
  if omittedOptions isnt true
    _.extend obj, _.omit(options, omittedOptions) # TODO allow a `extendTargetObj` option, e.g. the prototype?

  obj.dispose ?= Giraffe.dispose

  # Plug into `Giraffe.App` if one exists.
  obj.app ?= Giraffe.app
  Giraffe.bindAppEvents obj if obj.appEvents

  # If the object has an `initialize` function, wrap it with `beforeInitialize`
  # and `afterInitialize` and perform the necessary post-initialization.
  if obj.initialize
    Giraffe.wrapFn obj, 'initialize', null, _afterInitialize
  else
    _afterInitialize.call obj

  obj


###
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
###
Giraffe.defaultOptions = {}
  # omittedOptions: ["foo", "parse"]

  
# Is not a member of `Giraffe.defaultOptions` to make sure configured objects
# can freely implement `afterInitialize` without calls to `super`.
_afterInitialize = ->
  # Bind data events after `initialize` to catch any objects created in `initialize`
  Giraffe.bindDataEvents @ if @dataEvents


###
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
###
Giraffe.dispose = (args...) ->
  @trigger? 'disposing', @, args...
  @beforeDispose? args...
  @app = null
  @stopListening?()
  @trigger? 'disposed', @, args...
  @afterDispose? args...
  @


###
* Attempts to bind `appEvents` for an object. Called by `Giraffe.configure`.
###
Giraffe.bindAppEvents = (obj) ->
  Giraffe.bindEventMap obj, obj.app, obj.appEvents


###
* Binds the `dataEvents` hash that allows any instance property of `obj` to
* be bound to easily. Expects the form {'event1 event2 targetObj': 'handler'}.
* Called by `Giraffe.configure`.
###
Giraffe.bindDataEvents = (obj) ->
  dataEvents = obj.dataEvents
  return unless dataEvents
  dataEvents = obj.dataEvents() if typeof dataEvents is 'function'
  for eventKey, cb of dataEvents
    pieces = eventKey.split(' ')
    if pieces.length < 2
      error 'Data event must specify target object, ex: {\'change collection\': \'handler\'}'
      continue
    targetObj = pieces.pop()
    targetObj = if targetObj is 'this' or targetObj is '@' then obj else obj[targetObj] # allow listening to self
    if !targetObj
      error "Target object not found for data event '#{eventKey}'", obj
      continue
    eventName = pieces.join(' ')
    Giraffe.bindEvent obj, targetObj, eventName, cb
  obj


###
* Uses `Backbone.Events.listenTo` to make `contextObj` listen for `eventName` on
* `targetObj` with the callback `cb`, which can be a function or the string name
* of a method on `contextObj`.
*
* @param {Backbone.Events} contextObj The object doing the listening.
* @param {Backbone.Events} targetObj The object to listen to.
* @param {String/Function} eventName The name of the event to listen to.
* @param {Function} cb The event's callback.
###
Giraffe.bindEvent = (args...) ->
  args.push 'listenTo'
  _setEventBindings args...


# TODO accept partial params
###
* The `stopListening` equivalent of `bindEvent`.
*
* @param {Backbone.Events} contextObj The object doing the listening.
* @param {Backbone.Events} targetObj The object to listen to.
* @param {String/Function} eventName The name of the event to listen to.
* @param {Function} cb The event's callback.
###
Giraffe.unbindEvent = (args...) ->
  args.push 'stopListening'
  _setEventBindings args...


###
* Makes `contextObj` listen to `targetObj` for the events of `eventMap` in the
* form `eventName: method`, where `method` is a function or the name of a
* function on `contextObj`.
*
*     Giraffe.bindEventMap(this, this.app, this.appEvents);
*
* @param {Backbone.Events} contextObj The object doing the listening.
* @param {Backbone.Events} targetObj The object to listen to.
* @param {Object} eventMap A map of events to callbacks in the form {eventName: methodName/methodFn} to listen to.
###
Giraffe.bindEventMap = (args...) ->
  args.push 'listenTo'
  _setEventMapBindings args...


# TODO accept partial params
###
* The `stopListening` equivalent of `bindEventMap`.
*
* @param {Backbone.Events} contextObj The object doing the listening.
* @param {Backbone.Events} targetObj The object to listen to.
* @param {Object} eventMap A map of events to callbacks in the form {eventName: methodName/methodFn} to listen to.
###
Giraffe.unbindEventMap = (args...) ->
  args.push 'stopListening'
  _setEventMapBindings args...


# Event binding helpers
_setEventBindings = (contextObj, targetObj, eventName, cb, bindOrUnbindFnName) ->
  if typeof cb is 'string'
    cb = contextObj[cb]
  if typeof cb isnt 'function'
    error "callback for `'#{eventName}'` not found", contextObj, targetObj, cb
    return
  contextObj[bindOrUnbindFnName] targetObj, eventName, cb


_setEventMapBindings = (contextObj, targetObj, eventMap, bindOrUnbindFnName) ->
  eventMap = eventMap.call(contextObj) if typeof eventMap is 'function'
  return unless eventMap
  for eventName, cb of eventMap
    _setEventBindings contextObj, targetObj, eventName, cb, bindOrUnbindFnName
  contextObj


###
* Wraps `obj[fnName]` with `beforeFnName` and `afterFnName` invocations. Also
* calls the optional arguments `beforeFn` and `afterFn`.
*
* @param {Object} obj
* @param {String} fnName
* @param {Function} [beforeFn]
* @param {Function} [afterFn]
###
Giraffe.wrapFn = (obj, fnName, beforeFn, afterFn) ->
  fn = obj[fnName]
  return unless typeof fn is 'function'
  capFnName = fnName[0].toUpperCase() + fnName.slice(1)
  obj[fnName] = (args...) ->
    beforeFn?.apply obj, args
    obj['before' + capFnName]? args...
    result = fn.apply(obj, args)
    obj['after' + capFnName]? args...
    afterFn?.apply obj, args
    result
