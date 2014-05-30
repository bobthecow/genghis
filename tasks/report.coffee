gulp = require 'gulp'
sloc = require 'gulp-sloc'

# Misc code reporting.
gulp.task 'report', ->
  gulp.src([
    'client/js/**/*.{js,coffee}',
    'server/php/**/*.php',
    'server/rb/**.*.rb',
  ])
    .pipe(sloc())
