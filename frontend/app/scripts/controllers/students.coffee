angular.module('lgLessons').controller 'StudentsCtrl', (
  $rootScope
  $scope
  $http
  $modal
  $state
  baseApiUrl
  Classes
  Students
) ->

  checkIfPageLoaded = () ->
    if $scope.students? and $scope.classes?
      $rootScope.page_loaded = true

  defaultSearchOptions =
    q: ''
    order: ['-registration_date']
    page_size: 30

  $scope.search_options = angular.copy(defaultSearchOptions)

  # Used to trigger $watch even if search_options hasn't changed
  $scope.search_options.watchTrigger = true

  # ui.bootstrap.pagination ng-model should be object property
  # to allow manual changes
  $scope.pagination = currPage: 1

  $scope.$watch 'search_options', (newVal, oldVal) ->
    pullData(1)
  , true


  refreshPage = () ->
    angular.extend($scope.search_options, $scope.defaultSearchOptions)

    if $state.params.class_id isnt ""
      $state.go $state.current.name, class_id: ""

    $scope.search_options.watchTrigger = !$scope.search_options.watchTrigger


  pullData = (page) ->
    page = page or $scope.pagination.currPage
    params = angular.extend({}, $scope.search_options, page: page)

    $scope.data_loading = true

    $http
      .get "#{baseApiUrl}organisation_users/",
        params: params
      .success (students) ->
        # Pull Classes to assign class name to student
        Classes
          .get()
          .success (classes) ->
            $scope.classes = classes.results

            for student in students.results
              for classObj in $scope.classes
                for classStudentId in classObj.students
                  if classStudentId is student.id
                    student.class_name = classObj.name

            # Pull profile to get total number of students in ogranization
            $http
              .get("#{baseApiUrl}accounts/profile/")
              .success (profile) ->
                $scope.totalStudents = profile.organisation.num_of_students

                $scope.data_loading = false
                $scope.pagination.currPage = page

                $scope.students = students.results
                $scope.itemsPerPage = students.items_per_page
                $scope.totalItems = students.count

                checkIfPageLoaded()
      .error (data, status) ->
        if status is 400
          $state.go('404')


  # ng-change instead of $watch since
  # it's not triggered when changing model manually
  $scope.pageChanged = () -> pullData()


  $scope.switchClass = () ->
    $state.go $state.current.name, class_id: $scope.search_options.class_id


  $scope.getAvailableLicenses = () ->
    maxLicences = $scope.USER.organisation.num_of_max_licences or 0
    available = maxLicences - $scope.totalStudents

    if available > 0
      return available
    else
      return 0


  $scope.addStudent = () ->
    $modal.open
      templateUrl: '/views/students/add_student_modal.html'
      scope: $scope
      controller: ($scope, $modalInstance) ->
        $scope.form = {}

        $scope.sendForm = () ->
          $scope.sending = true

          Students
            .create $scope.form
            .success (data) ->
              $modalInstance.close()
              refreshPage()
            .error (data) ->
              $scope.sending = false
              $scope.error_msg = []

              if data['detail']
                $scope.error_msg.push(data['detail'])
              else
                $scope.error_msg = []
                $scope.error_msg.push(val[0]) for key, val of data

              $scope.errors = data


  $scope.editStudent = (student) ->
    $modal.open
      templateUrl: '/views/students/edit_student_modal.html',
      scope: $scope
      controller: ($scope, $modalInstance) ->
        $scope.student = angular.copy(student)
        $scope.modal = $modalInstance
    .result.then (updatedStudent) ->
      if updatedStudent.classes.length
        # Assign class name to student object
        # by finding class object in collection
        for classObj in $scope.classes
          if classObj.id is updatedStudent.classes[0]
            updatedStudent.class_name = classObj.name
      else
        updatedStudent.class_name = ""

      angular.extend(student, updatedStudent)


  $scope.deleteStudent = (student) ->
    $scope.data_loading = true

    if confirm 'Are you sure you want to delete this student?'
      $http
        .delete "#{baseApiUrl}organisation_users/#{student.id}/"
        .success () -> pullData(1)





angular.module('lgLessons').controller 'Students.ListCtrl', (
  $scope
  $state
) ->
  $scope.search_options.class_id = $state.params.class_id





angular.module('lgLessons').controller 'Students.EditCtrl', (
  baseApiUrl
  $scope
  $http
) ->
  $scope.form = angular.copy($scope.student)

  # Switch Form Params (API workaround)
  $scope.form.single_class = $scope.form.classes[0]
  delete $scope.form.classes

  $scope.sendForm = () ->
    return if $scope.sending

    $scope.sending = true
    $scope.success = null
    $scope.error_msg = null
    $scope.errors = null

    $http
      method: "patch"
      url:"#{baseApiUrl}organisation_users/#{$scope.form.id}/"
      data: $scope.form
    .success (data) -> $scope.modal.close(data)
    .error (data) ->
      $scope.error_msg = "Invalid Form"
      $scope.errors = data
      $scope.sending = false






angular.module('lgLessons').controller 'Students.ChangePassCtrl', (
  baseApiUrl
  $scope
  $http
) ->
  $scope.form = {}

  $scope.sendForm = () ->
    return if $scope.sending

    if $scope.form.new_password1 isnt $scope.form.new_password2
      return alert "Passwords doesn't match"

    $scope.sending = true
    $scope.success = null
    $scope.error_msg = null
    $scope.errors = null

    $http.post "#{baseApiUrl}organisation_users/#{$scope.student.id}/change_password/", $scope.form
      .success (data) ->
        $scope.success = true
      .error (data) ->
        $scope.error_msg = data.error_message
        $scope.errors = data.errors
      .finally (data) ->
        $scope.sending = false
