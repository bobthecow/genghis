# Backbone.Projections

Backbone.Projections is a library of projections for Backbone.Collection.

Projection is a read-only collection which contains some subset of an other
underlying collection and stays in sync with it. That means that projection will
respond correspondingly to `add`, `remove` and other events from an underlying
collection.

Currently there are four available projections — `Sorted`, `Reversed`, `Capped`
and `Filtered`.

See [blog post][] for examples and demos.

[blog post]: http://andreypopp.com/posts/2013-05-15-projections-for-backbone-collections.html

# Usage with Browserify

Install with npm, use with [Browserify][]:

    % npm install backbone.projections

and in your code

    BackboneProjections = require 'backbone.projections'

[Browserify]: http://browserify.org

# Usage with "globals"

Grab a copy of [backbone.projections.js][] which exports `BackboneProjections` as a
global.

[backbone.projections.js]: https://raw.github.com/andreypopp/backbone.projections/master/backbone.projections.js

## Sorted and Reversed

`Sorted` provides a projection which maintains its own order. You are
required to provide a comparator:

    {Sorted} = require 'backbone.projections'

    collection = new Collection([...])
    sorted = new Sorted(collection, comparator: (m) -> m.get('score'))

There's also a special case `Reversed` which maintains order reversed
to an underlying collection order.

    {Reversed} = require 'backbone.projections'

    collection = new Collection([...])
    sorted = new Reversed(collection)

## Capped

`Capped` provides a projection of a limited number of elements from an
underlying collection:

    {Capped} = require 'backbone.projections'

    collection = new Collection([...])
    capped = new Capped(collection, cap: 5)

Using `cap` parameter you can restrict the number of models capped collection
will contain. By default this projection tries to maintain the order of models
induced by underlying collection but you can also pass custom comparator, for
example

    topPosts = new Capped(posts,
      cap: 10
      comparator: (post) -> - post.get('likes'))

will create a `topPosts` collection which will contain first 10 most "liked"
posts from underlying `posts` collection.

## Filtered

`Filtered` provides a projection which contains a subset of models
from an underlying collection which match some predicate.

    {Filtered} = require 'backbone.projections'

    todaysPosts = new Filtered(posts,
      filter: (post) -> post.get('date').isToday())

The example above will create a `todaysPosts` projection which only contains
"today's" posts from the underlying `posts` collection.

By default this projection tries to maintain the order of models
induced by underlying collection but you can also pass custom comparator.

## Complex predicates which depend on some changing data

`Filtered` can be a base for complex projection which includes more
than a single collection, as an example we will implement a difference between
two collections:

    class Difference extends Filtered
      constructor: (underlying, subtrahend, options = {}) ->
        options.filter = (model) -> not subtrahend.contains(model)
        super(underlying, options)
        this.listenTo subtrahend, 'add remove reset', this.update.bind(this)


    a = new Model()
    b = new Model()
    c = new Model()
    d = new Model()

    underlying = new Collection [a, b, c]
    subtrahend = new Collection [b, c, d]

    diff = new Difference(underlying, subtrahend)

This way `diff` will contain only models from `underlying` which are not members
of `subtrahend` collection and what's more important `diff` will track changes
in `subtrahend` and update itself accordingly.

But that's a quick'n'dirty way of implementing this because on each change to
`subtrahend` the difference will reexamine entire `underlying` collection. Let's
implement this in a more efficient way:

    class EfficientDifference extends Filtered
      constructor: (underlying, subtrahend, options = {}) ->
        options.filter = (model) -> not subtrahend.contains(model)
        super(underlying, options)
        this.listenTo subtrahend,
          add: (model) =>
            this.remove(model) if this.contains(model)
          remove: (model) =>
            this.add(model) if this.underlying.contains(model)
          reset: this.update.bind(this)

## Composing projections

You can compose different projection which each other, for example

    todaysPosts = new Filtered(posts,
      filter: (post) -> post.get('date').isToday())
    topTodaysPosts = new Capped(todaysPosts,
      cap: 5
      comparator: (post) -> - post.get('likes'))

will result in a `topTodaysPosts` projection which only contains "top 5 most
liked posts from today".
