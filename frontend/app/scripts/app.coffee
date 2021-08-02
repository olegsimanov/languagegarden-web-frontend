angular.module('lgLessons', [
  'ngCookies'
  'ui.router'
  'ui.bootstrap'
  'ipCookie'
])
  .constant('baseApiUrl', '/api/v2/')
  .constant('defaultStateName', 'root')
  .config (
    $httpProvider
    $stateProvider
    $urlRouterProvider
    $locationProvider
    paginationConfig
  ) ->

    # Setup UI.Bootstrap Pagination
    paginationConfig.maxSize = 6
    paginationConfig.rotate = false


    # Setup $http requests
    $httpProvider.defaults.xsrfCookieName = 'csrftoken';
    $httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken';

    # Djano can't undestand params without this one, don't know why
    $httpProvider.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded';
    $httpProvider.defaults.headers.put['Content-Type'] = 'application/x-www-form-urlencoded';
    $httpProvider.defaults.headers.patch['Content-Type'] = 'application/x-www-form-urlencoded';
    $httpProvider.defaults.transformRequest = (data) ->
      if angular.isObject(data)
        return $.param(data)
      else
        return data


    $locationProvider.html5Mode(true)


    $stateProvider.layoutState = (name, options) ->
      unless options.template or options.templateUrl
        options.template = '<ui-view/>'

      unless name.split('.').length > 1
        options.parent ?= 'layout-panel'

      $stateProvider.state name, options


    $stateProvider.staticPage = (name, options) ->
      options.parent = 'layout-empty'
      options.controller ?= ($rootScope) -> $rootScope.page_loaded = true
      options.data ?= allowUnauthorized: true

      $stateProvider.state name, options


    # In Controllers, use $state.params instead of $stateParams, since second
    # doesn't work correctly with child state url: ':param' (ui-router v0.2.10)
    $stateProvider
      .state 'layout-auth',
        templateUrl: '/views/layout/auth.html'
      .state 'layout-panel',
        templateUrl: '/views/layout/panel.html'
      .state 'layout-empty',
        templateUrl: '/views/layout/empty.html'

      .state 'root',
        url: '/'
        controller: ($state, $rootScope) -> $state.go 'lessons'

      .layoutState 'lessons',
        url: '/browse/:category_id'
        controller: 'LessonsCtrl'
      .layoutState 'lessons.categories',
        url: '/categories'
        controller: 'LessonsCategoriesCtrl'
        templateUrl: '/views/lessons/categories.html'
      .layoutState 'lessons.list',
        url: '/list'
        controller: 'LessonsListCtrl'
        templateUrl: '/views/lessons/list.html'

      .layoutState 'users',
        abstract: true
        url: '/users'
        parent: 'layout-auth'
        data:
          allowUnauthorized: true
      .layoutState 'users.sign_in',
        url: '/sign_in'
        controller: 'SignInCtrl'
        templateUrl: '/views/users/sign_in.html'
      .layoutState 'users.sign_out',
        url: '/sign_out'
        controller: 'SignOutCtrl'
      .layoutState 'users.sign_up',
        url: '/sign_up'
        controller: 'SignUpCtrl'
        templateUrl: '/views/users/sign_up.html'
      .layoutState 'users.activate',
        url: '/activate/:activation_key/',
        controller: 'ActivateCtrl'
      .layoutState 'users.forgot_password',
        url: '/forgot_password',
        controller: 'ForgotPasswordCtrl'
        templateUrl: '/views/users/forgot_password.html'
      .layoutState 'users.reset_password',
        url: '/reset_password/:key/'
        controller: 'ResetPasswordCtrl'
        templateUrl: '/views/users/reset_password.html'

      .layoutState 'profile',
        abstract: true
        url: '/profile'
        templateUrl: '/views/profile/main.html'
      .layoutState 'profile.edit',
        url: '/edit'
        controller: 'Profile.EditCtrl'
        templateUrl: '/views/profile/edit.html'
      .layoutState 'profile.change_password',
        url: '/change_password'
        controller: 'Profile.ChangePasswordCtrl',
        templateUrl: '/views/profile/change_password.html'
      .layoutState 'profile.parse_xls',
        url: '/parse_xls',
        controller: 'Profile.ParseXLSCtrl',
        templateUrl: '/views/profile/parse_xls.html'
        data:
            adminPage:true

      .layoutState 'classes',
        url: '/classes',
        controller: 'ClassesCtrl',
        templateUrl: '/views/classes/list.html'

      .layoutState 'students',
        abstract: true
        url: '/students'
        controller: 'StudentsCtrl'
        templateUrl: '/views/students/list.html'
      .state 'students.list',
        url: '/:class_id'
        controller: 'Students.ListCtrl'

      .layoutState 'stats',
        abstract: true
        url: '/stats'
        templateUrl: '/views/stats/main.html'
      .layoutState 'stats.main',
        url: '/main'
        controller: 'StatsCtrl'
        templateUrl: '/views/stats/list.html'
      .layoutState 'stats.students',
        url: '/students'
        controller: 'StatsStudents'
        templateUrl: '/views/stats/students.html'
      .layoutState 'stats.lessons',
        url: '/lessons'
        controller: 'StatsLessons'
        templateUrl: '/views/stats/lessons.html'
      .layoutState 'stats.classes',
        url: '/classes'
        controller: 'StatsClasses'
        templateUrl: '/views/stats/classes.html'

      .layoutState 'admin_panel',
        url: '/organisation-info'
        controller: 'AdminPanelCtrl'
        templateUrl: '/views/admin_panel/admin_panel.html'

      .staticPage 'terms_of_service',
        url: '/terms_of_service'
        templateUrl: '/views/terms_of_service.html'

      .staticPage '404',
        url: '^*path'
        templateUrl: '/views/404.html'

  .run (
    $http
    $rootScope
    baseApiUrl
    defaultStateName
    $state
  ) ->

    $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState) ->
      $rootScope.page_loaded = false

      # If toState is 404 don't do anything
      return if toState.name is '404'

      # If User Signed in & Cached,
      # trying to open any users state besides sign_out
      if angular.isObject($rootScope.USER) and
         toState.name.indexOf('users.') > -1 and
         toState.name isnt 'users.sign_out'
        event.preventDefault()
        return $state.go defaultStateName

      # If Unauthorized
      if !toState.data?.allowUnauthorized and $rootScope.USER is null
        event.preventDefault()
        return $state.go 'users.sign_in'

      if toState.data?.adminPage and $rootScope.USER and (!$rootScope.USER.is_admin and !$rootScope.USER.organisation)
        event.preventDefault()
        return $state.go 'users.sign_in'

      # If We don't know User
      if $rootScope.USER is undefined
        event.preventDefault()
        $http.get("#{baseApiUrl}accounts/profile/")
          .success (data) ->
            $rootScope.USER = data
          .error (data) ->
            # Keep USER as null to prevent next requests for user profile
            $rootScope.USER = null
          .finally () ->
            $state.go toState.name, toParams
