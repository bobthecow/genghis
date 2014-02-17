{Collection} = window?.Backbone or require 'backbone'
{extend} = window?._ or require 'underscore'

inducedOrdering = (collection) ->
  func = (model) -> collection.indexOf(model)
  func.induced = true
  func

class exports.Filtered extends Collection

  constructor: (underlying, options = {}) ->
    this.underlying = underlying
    this.model = underlying.model
    this.comparator = options.comparator or inducedOrdering(underlying)
    this.options = extend {}, underlying.options, options
    super(this.underlying.models.filter(this.options.filter), options)

    this.listenTo this.underlying,
      reset: =>
        this.reset(this.underlying.models.filter(this.options.filter))
      remove: (model) =>
        this.remove(model) if this.contains(model)
      add: (model) =>
        this.add(model) if this.options.filter(model)
      change: (model) =>
        this.decideOn(model)
      sort: =>
        this.sort() if this.comparator.induced

  update: ->
    this.decideOn(model) for model in this.underlying.models

  decideOn: (model) ->
    if this.contains(model)
      this.remove(model) unless this.options.filter(model)
    else
      this.add(model) if this.options.filter(model)

exports.FilteredCollection = exports.Filtered
