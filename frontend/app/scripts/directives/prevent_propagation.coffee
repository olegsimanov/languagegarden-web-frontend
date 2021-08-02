angular.module('lgLessons').directive 'preventPropagation', () ->
  priority: 1000
  link: (scope, $el, attrs) ->
    $el.click (e) -> e.stopPropagation()
