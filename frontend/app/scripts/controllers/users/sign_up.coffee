angular.module('lgLessons').controller 'SignUpCtrl', (
  baseApiUrl
  $rootScope
  $scope
  $http
) ->
  $rootScope.page_loaded = true

  $scope.form = {}
  $scope.errors = {}
  $scope.sending = false


  $scope.sendForm = () ->
    return if $scope.sending

    if $scope.form.password1 isnt $scope.form.password2
      $scope.error_msg = "Passwords don't match"
      $scope.errors =
        password1: true
        password2: true
      return

    $scope.sending = true
    $scope.success = null

    $http.post("#{baseApiUrl}accounts/sign_up/", $scope.form)
      .success (data) ->
        $scope.success = true
        $scope.error_msg = null
        $scope.errors = null
      .error (data) ->
        $scope.error_msg = data.error_message
        $scope.errors = data.errors
      .finally () ->
        $scope.sending = false

