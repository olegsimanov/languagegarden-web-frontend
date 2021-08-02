angular.module('lgLessons').controller 'SignOutCtrl', (
  baseApiUrl
  $rootScope
  $scope
  $http
  $state
) ->

  $http.post "#{baseApiUrl}accounts/sign_out/"
    .finally (data) ->
      $rootScope.USER = null
      $state.go 'users.sign_in'
