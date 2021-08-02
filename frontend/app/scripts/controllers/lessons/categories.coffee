angular.module('lgLessons').controller 'LessonsCategoriesCtrl', (
  $rootScope
  $scope
  $state
  Syllabuses
) ->

  Syllabuses.get().then (categories) ->
    $scope.categories = categories.roots
    $scope.current_category = categories.byId[$state.params.category_id]
    $scope.breadcrumbs = categories.getPathForId($state.params.category_id)
    $rootScope.page_loaded = true
