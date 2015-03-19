gulp  = require 'gulp'
clean = require 'gulp-clean'

{log, colors} = require 'gulp-util'

# Remove all compiled assets.
gulp.task 'clean', ->
  log colors.blue('Cleaning previous builds')

  gulp.src(['public', 'tmp'])
    .pipe(clean())
