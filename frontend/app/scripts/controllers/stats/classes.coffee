angular.module('lgLessons').controller 'StatsClasses', (
  $rootScope
  $scope
  $state
  $http
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
                        users_activities = {}
                        for record in records.results
                            record.activity_records.score = record.calculated_score
                            if not users_activities[record.user_id]
                                users_activities[record.user_id] = {}
                                users_activities[record.user_id][record.lesson_id] = {
                                    lesson: record.lesson,
                                    activities: [record.activity_records]
                                }
                            else if users_activities[record.user_id][record.lesson_id]
                                users_activities[record.user_id][record.lesson_id].activities.push(record.activity_records)
                            else
                                users_activities[record.user_id][record.lesson_id] = {
                                    lesson: record.lesson,
                                    activities: [record.activity_records]
                                }
                        Classes
                            .get()
                            .success (classes) ->
                                $scope.classes = classes.results

                                for act of users_activities
                                    initial = 0
                                    final = 0
                                    count = 0
                                    for lesson of users_activities[act]
                                        if lesson != 'user'
                                            initial += users_activities[act][lesson].activities[0].score
                                            final += users_activities[act][lesson].activities[users_activities[act][lesson].activities.length-1].score
                                            count += 1

                                    for classObj in $scope.classes
                                        classObj.divider = if not classObj.divider then 0 else classObj.divider
                                        classObj.total = if not classObj.total then 0 else classObj.total
                                        classObj.final = if not classObj.final then 0 else classObj.final
                                        classObj.initial = if not classObj.initial then 0 else classObj.initial
                                        for classStudentId in classObj.students
                                            if classStudentId is parseInt(act)
                                                classObj.total += Object.keys(users_activities[act]).length
                                                classObj.final += final/count
                                                classObj.initial += initial/count
                                                classObj.divider++
                        $scope.users_activities = users_activities

                        $scope.data_loading = false
                        $scope.pagination.currPage = page

                        $scope.students = students.results
                        $scope.itemsPerPage = 30
                        $scope.totalItems = Object.keys(users_activities).length

                        checkIfPageLoaded()

    $scope.pageChanged = () -> pullData()