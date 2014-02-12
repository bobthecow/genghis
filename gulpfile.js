'use strict';

var gulp = require('gulp');

require('./tasks/build');
require('./tasks/clean');
require('./tasks/copy');
require('./tasks/lint');
require('./tasks/report');
require('./tasks/scripts');
require('./tasks/styles');
require('./tasks/templates');

var watch = require('./tasks/watch');

// By default, build all the things!
gulp.task('default', ['rebuild'], watch);
