({

  baseUrl: 'assets/js',
  name:    'almond',
  include: ['genghis/boot', 'modernizr-detects'],
  out:     'tmp/genghis.js',

  optimize:                'none',
  inlineText:              true,
  preserveLicenseComments: false,

  stubModules: ['text', 'hgn', 'css', 'less'],

  pragmasOnSave: {
    excludeHogan:      true,
    excludeAfterBuild: true
  },

  uglify2: {
    output: {ascii_only: true}
  },

  paths: {
    'almond':                   '../vendor/almond/almond',
    'backbone':                 '../vendor/backbone/backbone',
    'backgrounds-dev':          '../css/backgrounds-dev',
    'bootstrap.dropdown':       '../vendor/bootstrap/js/bootstrap-dropdown',
    'bootstrap.modal':          '../vendor/bootstrap/js/bootstrap-modal',
    'bootstrap.popover':        '../vendor/bootstrap/js/bootstrap-popover',
    'bootstrap.tooltip':        '../vendor/bootstrap/js/bootstrap-tooltip',
    'codemirror':               '../vendor/codemirror/lib/codemirror',
    'codemirror.matchbrackets': '../vendor/codemirror/addon/edit/matchbrackets',
    'codemirror.javascript':    '../vendor/codemirror/mode/javascript/javascript',
    'esprima':                  '../vendor/esprima/esprima',
    'hgn':                      '../vendor/requirejs-hogan-plugin/hgn',
    'hogan':                    '../vendor/requirejs-hogan-plugin/hogan',
    'jquery':                   '../vendor/jquery/jquery',
    'jquery.hoverintent':       '../vendor/jquery-hoverIntent/jquery.hoverIntent',
    'jquery.tablesorter':       '../vendor/jquery.tablesorter/js/jquery.tablesorter',
    'keyscss':                  '../vendor/keyscss/keys',
    'mousetrap':                '../vendor/mousetrap/mousetrap',
    'style':                    '../css/style',
    'text':                     '../vendor/requirejs-hogan-plugin/text',
    'underscore':               '../vendor/underscore/underscore'
  },

  packages: [
    {
      name:     'css',
      location: '../vendor/require-css',
      main:     'css'
    },
    {
      name:     'less',
      location: '../vendor/require-less',
      main:     'less'
    }
  ],

  shim: {
    'backbone': {
      deps:    ['underscore', 'jquery'],
      exports: 'Backbone'
    },

    'bootstrap.dropdown': ['jquery'],
    'bootstrap.tooltip':  ['jquery'],
    'bootstrap.popover':  ['jquery', 'bootstrap.tooltip'],
    'bootstrap.modal':    ['jquery'],

    'codemirror':               {exports: 'CodeMirror'},
    'codemirror.matchbrackets': ['codemirror'],
    'codemirror.javascript':    ['codemirror'],

    'underscore': {exports: '_'},

    'jquery.hoverintent': ['jquery'],
    'jquery.tablesorter': ['jquery'],

    'modernizr': {exports: 'Modernizr'}
  },

})
