angular.module('lgLessons').controller 'LessonsCtrl', (
  $scope
  $state
  Syllabuses
) ->

  Syllabuses.get().then (categories) ->
    category = categories.byId[$state.params.category_id]

    if category
      if category.level is 0
        $state.go 'lessons.categories', category_id: category.id
      else
        $state.go 'lessons.list', category_id: category.id
    else
      $state.go 'lessons.categories', category_id: 'all'
