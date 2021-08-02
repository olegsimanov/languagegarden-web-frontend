angular.module('lgLessons').controller 'ResetPasswordCtrl', (
  baseApiUrl
  $scope
  $rootScope
  $http
  $stateParams
  $state
) ->
  $rootScope.page_loaded = true

  $scope.form = {}
  $scope.errors = null
  $scope.sending = false


  $scope.sendForm = () ->
    return if $scope.sending

    if $scope.form.new_password1 isnt $scope.form.new_password2
      alert "Passwords doesn't match"
      return

    $scope.sending = true
    $scope.error_msg = null
    $scope.errors = null

    $http.post("#{baseApiUrl}accounts/reset_password/#{$stateParams.key}/", $scope.form)
      .success () ->
        $state.go('users.sign_in').then () ->
          $rootScope.$broadcast 'pass_changed'
      .error (data) ->
        $scope.errors = data.errors
        $scope.error_msg = data.error_message
        $scope.sending = false

