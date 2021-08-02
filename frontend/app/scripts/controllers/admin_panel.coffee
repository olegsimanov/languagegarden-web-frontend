angular.module('lgLessons').controller 'AdminPanelCtrl', (
  baseApiUrl
  $scope
  $http
  $rootScope
  $state
) ->

  $http.get "#{baseApiUrl}organisation_users_admin/"
    .success (data) ->
      $rootScope.page_loaded = true
      $scope.data = data
    .error (data, status) ->
      if status is 400
        $state.go('404')
