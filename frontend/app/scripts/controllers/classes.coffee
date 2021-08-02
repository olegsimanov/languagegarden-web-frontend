angular.module('lgLessons').controller 'ClassesCtrl', (
  $scope
  $rootScope
  $modal
  $http
  $state
  Classes
  baseApiUrl
) ->

  Classes
    .get()
    .success (data) ->
      $scope.classes = data.results
      $rootScope.page_loaded = true


  $scope.showStudents = (classId) ->
    $state.go 'students.list', class_id: classId


  $scope.addClass = () ->
    $modal.open
      templateUrl: '/views/classes/form-modal.html'
      scope: $scope
      controller: ($scope, $modalInstance) ->
        $scope.form = {}

        $scope.sendForm = () ->
          Classes
            .create($scope.form)
            .success (data) ->
              $scope.classes.push(data)
              $modalInstance.close()
            .finally () ->
              $scope.sending = false


  $scope.editClass = (classObject) ->
    $modal.open
      templateUrl: '/views/classes/form-modal.html'
      scope: $scope
      controller: ($scope, $modalInstance) ->
        $scope.form = angular.copy(classObject)
        $scope.edit_state = true

        $scope.sendForm = () ->
          Classes
            .update(classObject.id, $scope.form)
            .success (data) ->
              angular.extend(classObject, data)
              $modalInstance.close()


  $scope.deleteClass = (classId, $index) ->
    if confirm 'Are you sure you want to delete this class?'
      Classes.remove(classId)
      $scope.classes.splice($index, 1)
