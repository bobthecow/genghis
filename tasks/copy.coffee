gulp    = require 'gulp'
changed = require 'gulp-changed'
# notify  = require 'gulp-notify'

{log, colors} = require 'gulp-util'

livereload = require './livereload'

# Copy static assets over to public directory
gulp.task 'copy', ->
  log colors.blue('Copying static assets')

  gulp.src('client/img/**/*.*')
    .pipe(changed('public/img'))
    .pipe(gulp.dest('public/img'))
    .pipe(livereload())
#     .pipe(notify(
#       message: 'Images updated',
#       onLast:  true
#     ))
