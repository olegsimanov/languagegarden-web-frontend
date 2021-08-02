angular.module('lgLessons').controller 'ForgotPasswordCtrl', (
  baseApiUrl
  $rootScope
  $scope
  $http
) ->
  $rootScope.page_loaded = true

  $scope.form = {}
  $scope.errors = {}
  $scope.sending = false
  $scope.show_info = true


  $scope.sendForm = () ->
    return if $scope.sending

    $scope.sending = true
    $scope.success = null
    $scope.error_msg = null

    $http.post("#{baseApiUrl}accounts/reset_password_send_email/", $scope.form)
      .success (data) ->
        $scope.success = true
      .error (data) ->
        $scope.error_msg = data.error_message
      .finally () ->
        $scope.show_info = false
        $scope.sending = false
