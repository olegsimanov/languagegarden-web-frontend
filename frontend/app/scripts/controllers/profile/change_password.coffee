angular.module('lgLessons').controller 'Profile.ChangePasswordCtrl', (
  baseApiUrl
  $rootScope
  $scope
  $http
) ->
  $rootScope.page_loaded = true

  $scope.form = {}
  $scope.sending = false


  $scope.sendForm = () ->
    return if $scope.sending

    if $scope.form.new_password1 isnt $scope.form.new_password2
      $scope.error_msg = "Passwords don't match"
      $scope.errors =
        new_password1: true
        new_password2: true
      return

    $scope.sending = true

    $http.post "#{baseApiUrl}accounts/change_password/", $scope.form
      .success (data) ->
        $scope.errors = {}
        $scope.error_msg = false
        $scope.success = true
      .error (data) ->
        $scope.error_msg = data.error_message
        $scope.errors = data.errors
      .finally () ->
        $scope.sending = false
