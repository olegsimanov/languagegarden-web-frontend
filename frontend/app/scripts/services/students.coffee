angular.module('lgLessons').service 'Students', (
  $http
  baseApiUrl
) ->

  @create = (data) ->
    $http.post "#{baseApiUrl}organisation_users/", data


  return @
