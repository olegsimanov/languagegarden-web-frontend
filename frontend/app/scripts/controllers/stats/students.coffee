angular.module('lgLessons').controller 'StatsStudents', (
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
    $scope.class_filter = ""

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
                Classes
                    .get()
                    .success (classes) ->
                        $scope.classes = classes.results

                        for student in students.results
                            for classObj in $scope.classes
                                for classStudentId in classObj.students
                                    if classStudentId is student.id
                                        student.class_name = classObj.name
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
                                    for student in students.results
                                        if student.id == record.user_id
                                            users_activities[record.user_id].user = student
                                for act of users_activities
                                    initial = 0
                                    final = 0
                                    count = 0
                                    for lesson of users_activities[act]
                                        if lesson != 'user'
                                            initial += users_activities[act][lesson].activities[0].score
                                            final += users_activities[act][lesson].activities[users_activities[act][lesson].activities.length-1].score
                                            count += 1

                                    users_activities[act].total = Object.keys(users_activities[act]).length-1;
                                    users_activities[act].final = final/count
                                    users_activities[act].initial = initial/count
                                $scope.users_activities = users_activities
                                console.log $scope.users_activities
                                $scope.data_loading = false
                                $scope.pagination.currPage = page

                                $scope.students = students.results
                                $scope.itemsPerPage = 30
                                $scope.totalItems = Object.keys(users_activities).length

                                checkIfPageLoaded()

    $scope.pageChanged = () -> pullData()