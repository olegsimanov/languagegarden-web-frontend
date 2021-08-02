angular.module('lgLessons').filter('thumbnail', ->
    (value, type) ->
        replacer = (match, p1) -> '_' + type + '.' + p1
        value.replace(/\.(\w+)$/, replacer)
)
