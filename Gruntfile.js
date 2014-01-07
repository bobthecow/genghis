var Datauri = require('datauri');

module.exports = function(grunt) {
  'use strict';

  var VERSION = grunt.file.read('VERSION.txt');
  var BANNER  = grunt.template.process(grunt.file.read('src/templates/banner.txt'), {data: {version: VERSION}});

  grunt.initConfig({
    clean: ['tmp/'],

    jshint: ['Gruntfile.js', 'assets/js/**/*.js'],

    requirejs: {
      release: {
        options: {
          mainConfigFile:          'assets/js/config.js',
          include:                 ['genghis/boot', 'modernizr-detects'],
          out:                     'tmp/genghis.js',
          optimize:                'none',
          inlineText:              true,
          name:                    'almond',
          baseUrl:                 'assets/js',
          wrap:                    true,
          generateSourceMaps:      false,
          preserveLicenseComments: false,

          stubModules:             ['text', 'hgn', 'css', 'less'],

          pragmasOnSave: {
            excludeHogan:      true,
            excludeAfterBuild: true
          },

          uglify2: {
            output: {ascii_only: true}
          }
        }
      }
    },

    less: {
      release: {
        options: {
          paths: ['assets/css']
        },
        files: {
          'tmp/genghis.css': 'assets/css/style.less'
        }
      }
    },

    uglify: {
      release: {
        options: {
          banner: BANNER + "\n",
          beautify: {
            ascii_only: true
          }
        },
        files: {
          'tmp/script.js': 'tmp/genghis.js'
        }
      }
    },

    cssmin: {
      release: {
        options: {
          banner: BANNER,
          keepSpecialComments: 0,
        },
        files: {
          'tmp/style.css': [
            'assets/vendor/codemirror/lib/codemirror.css',
            'assets/vendor/keyscss/keys.css',
            'tmp/backgrounds.css',
            'tmp/genghis.css'
          ]
        }
      }
    },

    htmlmin: {
      release: {
        options: {
          removeComments:            true,
          collapseWhitespace:        true,
          collapseBooleanAttributes: true,
          removeRedundantAttributes: true,
          removeEmptyAttributes:     true
        },
        files: {
          'tmp/index.html.mustache.tpl': 'src/templates/index.html.mustache.tpl',
          'tmp/error.html.mustache.tpl': 'src/templates/error.html.mustache.tpl'
        }
      }
    },

    dataUri: {
      backgrounds: {
        src:  ['assets/css/backgrounds.css'],
        dest: 'tmp',
        options: {
          target: ['assets/img/backgrounds/*.*']
        }
      }
    },

    concat: {
      assets: {
        options: {
          process: function(src, filepath) {
            var name = filepath.replace(/^tmp\/|\.mustache\.tpl$/g, '');
            src = src
              .replace('<%= favicon_uri %>',  Datauri('assets/img/favicon.png'))
              .replace('<%= keyboard_uri %>', Datauri('assets/img/keyboard.png'));

            return "\n@@" + name + "\n" + src;
          }
        },
        src: [
          'tmp/index.html.mustache.tpl',
          'tmp/error.html.mustache.tpl',
          'tmp/style.css',
          'tmp/script.js'
        ],
        dest: 'tmp/assets.txt'
      },

      'lib-rb': {
        src: [
          'src/rb/genghis/json.rb',
          'src/rb/genghis/errors.rb',
          'src/rb/genghis/models/**/*',
          'src/rb/genghis/helpers.rb',
          'src/rb/genghis/server.rb'
        ],
        dest: 'tmp/lib.rb'
      },

      'lib-php': {
        options: {
          process: function(src, filepath) {
            return src.replace(/^<\?php\n\s*/, '')
          }
        },
        src: [
          'src/php/**/*.php',
          '!src/php/Genghis/AssetLoader/Dev.php'
        ],
        dest: 'tmp/lib.php'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-htmlmin');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-requirejs');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-data-uri');

  grunt.registerTask('build:script',    ['requirejs', 'uglify']);
  grunt.registerTask('build:style',     ['dataUri', 'less', 'cssmin']);
  grunt.registerTask('build:templates', ['htmlmin']);
  grunt.registerTask('build:assets',    ['build:script', 'build:style', 'build:templates', 'concat:assets']);

  grunt.registerTask('build:php', '...', function() {
    var src = grunt.file.read('src/templates/genghis.php.tpl')
      .replace(/<%= version %>/g,  VERSION)
      .replace('<%= includes %>', grunt.file.read('tmp/lib.php').replace(/^<?php\n\s*/, ''))
      .replace('<%= assets %>',   grunt.file.read('tmp/assets.txt'));

    grunt.file.write('genghis.php', src);
  });

  grunt.registerTask('build:rb', '...', function() {
    var src = grunt.file.read('src/templates/genghis.rb.tpl')
      .replace(/<%= version %>/g, VERSION)
      .replace('<%= includes %>', grunt.file.read('tmp/lib.rb'))
      .replace('<%= assets %>',   grunt.file.read('tmp/assets.txt'));

    grunt.file.write('genghis.rb', src);
  });

  grunt.registerTask('build', ['build:assets', 'concat:lib-php', 'concat:lib-rb', 'build:php', 'build:rb']);

  grunt.registerTask('default', ['clean', 'build']);

};
