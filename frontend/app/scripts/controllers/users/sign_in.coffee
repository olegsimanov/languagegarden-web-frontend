angular.module('lgLessons').controller 'SignInCtrl', (
  baseApiUrl
  $rootScope
  $scope
  $http
  $state
) ->
  $rootScope.page_loaded = true

  $scope.form = {}
  $scope.errors = {}
  $scope.sending = false


  $scope.$on 'activate', (e, data) ->
    $scope.activate = data

  $scope.$on 'pass_changed', () ->
    $scope.pass_changed = true


  $scope.sendForm = () ->
    return if $scope.sending

    $scope.sending = true
    $scope.errors = null
    $scope.error_msg = null

    $http.post("#{baseApiUrl}accounts/sign_in/", $scope.form)
      .success (data) ->
        $rootScope.USER = data.user
        $state.go 'root'
      .error (data) ->
        $scope.error_msg = data.error_message
        $scope.sending = false

