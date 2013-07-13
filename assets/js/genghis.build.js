var _requirejs = require('requirejs');

_requirejs.optimize({
  appDir:  '../../',
  baseUrl: '../../',
  dir:     '../../public',

  mainConfigFile: './genghis.js',
  name:           'genghis',
  out:            '../../public/js/genghis.js'

  optimizeCss: 'standard',
  inlineText:  true,

  stubModules: ['text', 'hgn'],

  pragmasOnSave: {
    excludeHogan: true,
    excludeAfterBuild: true
  },
});
