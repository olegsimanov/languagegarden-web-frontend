angular.module('lgLessons').directive 'openUrl', () ->
  scope:
    url: '@openUrl'
    target: '@openUrlTarget'

  link: (scope, $el, attrs) ->
    $el.click (e) ->
      e.preventDefault()
      window.open scope.url, scope.target
