angular.module('lgLessons').controller 'StatsLessons', (
  $rootScope
  $scope
  $http
  $modal
  baseApiUrl
  Syllabuses
  Lessons
  Classes
) ->

    checkIfPageLoaded = () ->
        if $scope.students? and $scope.users_activities?
            $rootScope.page_loaded = true

    defaultSearchOptions =
        q: ''
        order: ['-registration_date']
        page_size: 30
    $scope.$watch 'search_options', (newVal, oldVal) ->
        pullData(1)
    , true
    $scope.search_options = angular.copy(defaultSearchOptions)
    # Used to trigger $watch even if search_options hasn't changed
    $scope.search_options.watchTrigger = true

    # ui.bootstrap.pagination ng-model should be object property
    # to allow manual changes
    $scope.pagination = currPage: 1
    pullData = (page) ->
        page = page or $scope.pagination.currPage
        params = angular.extend({}, $scope.search_options, {page: page, page_size: 99999})

        $scope.data_loading = true

        $http
            .get "#{baseApiUrl}organisation_users/",
                params: params
            .success (students) ->
                params = angular.extend({}, $scope.search_options, page_size: 99999)
                $http
                    .get "#{baseApiUrl}lesson_records/",
                        params: params
                    .success (records) ->
                        $scope.records = records
                        users_activities = {}
                        for record in records.results
                            if not users_activities[record.lesson_id]
                                users_activities[record.lesson_id] = {
                                    name: record.lesson,
                                    activities: [record.activity_records],
                                    score: record.calculated_score
                                }
                            else
                                users_activities[record.lesson_id].activities.push(record.activity_records)

                        finalized_activities = {}
                        number_of_lesson = 0
                        for lesson of users_activities
                            if not finalized_activities[lesson]
                                finalized_activities[lesson] = {}
                            for act in users_activities[lesson].activities
                                counter = 1
                                for single_act in act.reverse()
                                    if single_act.done
                                        if finalized_activities[lesson][single_act.activity_id]
                                            finalized_activities[lesson][single_act.activity_id].score += (1+single_act.num_of_failures)
                                            finalized_activities[lesson][single_act.activity_id].counter += 1
                                        else
                                            finalized_activities[lesson][single_act.activity_id] =
                                                score: 1+single_act.num_of_failures,
                                                name: if single_act.activity != "Unnamed Activity" then single_act.activity else counter
                                                counter: 1
                                        counter++
                        $scope.finalized_activities = finalized_activities
                        $scope.users_activities = users_activities

                        $scope.data_loading = false
                        $scope.pagination.currPage = page

                        $scope.students = students.results
                        $scope.itemsPerPage = 30
                        $scope.totalItems = Object.keys(users_activities).length

                        checkIfPageLoaded()

    $scope.pageChanged = () -> pullData()

    $scope.showLesson = (lesson_id) ->
        $scope.one_lesson = {}
        $scope.fake_number = 0
        for record in $scope.records.results
            if record.lesson_id == parseInt(lesson_id)
                global_counter = 0
                if not $scope.one_lesson[record.user_id]
                    $scope.one_lesson[record.user_id] = []
                    for act in record.activity_records
                        if act.done
                            $scope.one_lesson[record.user_id].push(
                                tries: act.num_of_failures,
                                counter: 1
                            )
                            global_counter++
                else
                    counter = 0
                    for act in record.activity_records
                        if act.done
                            $scope.one_lesson[record.user_id][counter].tries += act.num_of_failures
                            $scope.one_lesson[record.user_id][counter].counter += 1
                            counter++
                            global_counter++
                for student in $scope.students
                    if student.id == record.user_id
                        $scope.one_lesson[record.user_id].user = student
                if $scope.fake_number < global_counter
                    $scope.fake_number = global_counter
        $modal.open
            templateUrl: '/views/stats/lesson_stats_modal.html',
            scope: $scope
            windowClass: "large_css_modal"
            controller: ($scope, $modalInstance) ->
                $scope.current_lesson = $scope.users_activities[lesson_id]
                $scope.modal = $modalInstance
        .result.then (updatedStudent) ->
    $scope.getNumber = (ind) ->
        new Array(ind)
angular.module('lgLessons').controller 'StatsLessonsModal', (
  baseApiUrl
  $scope
  $http
) ->
