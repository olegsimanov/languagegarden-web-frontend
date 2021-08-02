angular.module('lgLessons').controller 'LessonsListCtrl', (
  $rootScope
  $scope
  $state
  Syllabuses
  Lessons
) ->

  Syllabuses.get().then (categories) ->
    category = categories.byId[$state.params.category_id]

    if category.level is 1
      $scope.year_category = category
      $scope.categories = category.children
    else
      $scope.year_category = category.parent
      $scope.categories = category.parent.children

    $scope.breadcrumbs = categories.getPathForId($state.params.category_id)

    Lessons
      .get
        score: true
        syllabus_id: [category.id]
        page_size: 9999
      .success (data) ->
        $scope.lessons = data.results
        $rootScope.page_loaded = true
