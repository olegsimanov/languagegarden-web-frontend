angular.module('lgLessons').service 'Lessons', (
  $http
  baseApiUrl
) ->

  @get = (params) ->
    $http.get "#{baseApiUrl}lessons/", params: params


  return @
