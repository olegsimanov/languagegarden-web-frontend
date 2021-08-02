angular.module('lgLessons').directive 'autofocus', () ->
  priority: 99999
  link: (scope, $el, attrs) ->
    # Move caret to the end of :input value
    # http://stackoverflow.com/a/10576409
    $el.focus () ->
      @selectionStart = @selectionEnd = @value.length

    setTimeout () ->
      $el.focus()
    , 100
