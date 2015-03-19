{Giraffe} = require('../vendors')

# Let's use a base class!
class View extends Giraffe.View
  # Really, Hogan, but it looks a lot like JST:
  templateStrategy: 'jst'

  # By default return the model, or the view if no model is set.
  serialize: -> @model or this

module.exports = View
