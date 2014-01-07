require.config({
  paths: {
    'almond':                   '../vendor/almond/almond',
    'backbone':                 '../vendor/backbone/backbone',
    'backbone.declarative':     '../vendor/backbone.declarative/backbone.declarative',
    'backbone.giraffe':         '../vendor/backbone.giraffe/dist/backbone.giraffe',
    'backbone.mousetrap':       '../vendor/backbone.mousetrap/backbone.mousetrap',
    'backgrounds':              '../css/backgrounds',
    'bootstrap.dropdown':       '../vendor/bootstrap/js/dropdown',
    'bootstrap.modal':          '../vendor/bootstrap/js/modal',
    'bootstrap.popover':        '../vendor/bootstrap/js/popover',
    'bootstrap.tooltip':        '../vendor/bootstrap/js/tooltip',
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

    'backbone.declarative': ['backbone'],

    'backbone.giraffe': {
      deps:    ['backbone-stack'],
      exports: 'Giraffe'
    },

    'backbone.mousetrap': ['backbone', 'mousetrap'],

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

});
