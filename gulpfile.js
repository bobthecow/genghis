'use strict';

var gulp = require('gulp');

require('coffee-script/register');

require('./tasks/build.coffee');
require('./tasks/clean.coffee');
require('./tasks/copy.coffee');
require('./tasks/lint.coffee');
require('./tasks/report.coffee');
require('./tasks/scripts.coffee');
require('./tasks/styles.coffee');
require('./tasks/templates.coffee');

var watch = require('./tasks/watch.coffee');

// By default, build all the things!
gulp.task('default', ['rebuild'], watch);
