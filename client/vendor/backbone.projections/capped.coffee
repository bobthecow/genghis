{Collection} = window?.Backbone or require 'backbone'
{toArray, extend} = window?._ or require 'underscore'

inducedOrdering = (collection) ->
  func = (model) -> collection.indexOf(model)
  func.induced = true
  func

class exports.Capped extends Collection

  constructor: (underlying, options = {}) ->
    this.underlying = underlying
    this.model = underlying.model
    this.comparator = options.comparator or inducedOrdering(underlying)
    this.options = extend {cap: 5}, underlying.options, options
    super(this._capped(this.underlying.models), options)

    this.listenTo this.underlying,
      reset: =>
        this.reset(this._capped(this.underlying.models))
      remove: (model) =>
        if this.contains(model)
          this.remove(model)
          capped = this._capped(this.underlying.models)
          this.add(capped[this.options.cap - 1])
      add: (model) =>
        if this.length < this.options.cap
          this.add(model)
        else if this.comparator(model) < this.comparator(this.last())
          # TODO: check if Backbone.Collection does a stable sort
          this.add(model)
          this.remove(this.at(this.options.cap))
      sort: =>
        this.reset(this._capped(this.underlying.models)) if this.comparator.induced

  _capped: (models) ->
    models = toArray(models)
    models.sort (a, b) =>
      a = this.comparator(a)
      b = this.comparator(b)
      if a > b then 1
      else if a < b then -1
      else 0
    models.slice(0, this.options.cap)

  resize: (cap) ->
    if this.options.cap > cap
      this.options.cap = cap
      for model, idx in this.models by -1
        break if idx < cap
        this.remove(model)
    else if this.options.cap < cap
      this.options.cap = cap
      capped = this._capped(this.underlying.models)
      this.add(capped.slice(this.length, this.options.cap))
    this.trigger('resize')

exports.CappedCollection = exports.Capped
