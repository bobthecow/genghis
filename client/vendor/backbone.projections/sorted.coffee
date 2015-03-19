{Collection} = window?.Backbone or require 'backbone'
{extend} = window?._ or require 'underscore'

class exports.Sorted extends Collection

  constructor: (underlying, options = {}) ->
    throw new Error("provide a comparator") unless options.comparator
    this.underlying = underlying
    this.model = underlying.model
    this.comparator = options.comparator
    this.options = extend {}, underlying.options, options
    super(this.underlying.models, options)

    this.listenTo this.underlying,
      reset: =>
        this.reset(this.underlying.models)
      remove: (model) =>
        this.remove(model)
      add: (model) =>
        this.add(model)

class exports.Reversed extends exports.Sorted

  constructor: (underlying, options = {}) ->
    options.comparator = (model) -> - underlying.indexOf(model)
    super(underlying, options)
    this.listenTo this.underlying,
      sort: this.sort

exports.SortedCollection = exports.Sorted
exports.ReversedCollection = exports.Reversed
