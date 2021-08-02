angular.module('lgLessons').controller 'Profile.EditCtrl', (
  baseApiUrl
  $scope
  $http
  $rootScope
) ->
  $rootScope.page_loaded = true

  $scope.form =
    email: $scope.USER.email
    first_name: $scope.USER.first_name
    last_name: $scope.USER.last_name
  $scope.sending = false


  $scope.sendForm = () ->
    return if $scope.sending

    $scope.sending = true

    $http.post "#{baseApiUrl}accounts/update_info/", $scope.form
      .success (data) ->
        $scope.errors = {}
        $scope.error_message = false
        $scope.success = true
        $rootScope.USER = data
      .error (data) ->
        $scope.error_msg = data.error_message
        $scope.errors = data.errors
      .finally () ->
        $scope.sending = false
