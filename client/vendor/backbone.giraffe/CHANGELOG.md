## Changelog


### 0.1.5

- Added events around several view methods: `rendering`, `rendered`,
  `attaching`, `attached`, `detaching`, `detached`

- ___BREAKING CHANGE:___ `dispose` now acts on `this` instead of taking the
  target object as an argument. Removed `disposeThis` as it's now redundant.

- Registered as a Bower package: `bower install backbone.giraffe`

### 0.1.4


- Added the function `Giraffe.configure` which 
  [mixes several Giraffe features](http://barc.github.io/backbone.giraffe/backbone.giraffe.html#configure)
  into any object. Used in the constructors of all Giraffe objects.

- `omittedOptions` can be used to prevent `Giraffe.configure` from extending
  particular properties. If the value is `true`, all properties are omitted.

- The document event prefix `'data-gf-'` is now configurable via
  `Giraffe.View.setDocumentEventPrefix` and as a parameter to 
  `Giraffe.View.setDocumentEvents` and `Giraffe.View.removeDocumentEvents`.

- ___BREAKING CHANGE:___ `dispose` is now mixed into configured objects
  with a default function, and is only copied if it doesn't exist.
  As a result, calls to super in `dispose` no longer make sense.
  Use `Giraffe.dispose` instead.

- `beforeDispose`, `afterDispose`, `beforeInitialize`, and `afterInitialize`
  are called if defined on all configured objects. Some are used by Giraffe
  objects so override with care.

- Added `Giraffe.wrapFn` which calls 'beforeFnName' and 'afterFnName' versions
  of a function name on an object. Here's a reference for future development - 
  [__Backbone.Advice__](https://github.com/rhysbrettbowen/Backbone.Advice)