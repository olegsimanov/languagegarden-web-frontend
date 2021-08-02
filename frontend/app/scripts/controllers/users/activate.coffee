angular.module('lgLessons').controller 'ActivateCtrl', (
  baseApiUrl
  $rootScope
  $scope
  $http
  $state
  $stateParams
  defaultStateName
) ->

  statusObj = {}

  $http.post("#{baseApiUrl}accounts/activate/#{$stateParams.activation_key}/")
    .success () ->
      statusObj.success = true
    .error (data) ->
      statusObj.success = false
      statusObj.error = data.error_message
    .finally (data) ->
      # we deleting the USER so it will be undefined (not null!) and the
      # state change handler will be forced to load the profile
      delete $rootScope.USER
      $state.go defaultStateName
