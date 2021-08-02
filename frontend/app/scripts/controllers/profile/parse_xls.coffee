angular.module('lgLessons').controller 'Profile.ParseXLSCtrl', (
  baseApiUrl
  $scope
  $http
  $rootScope
  Cookies
) ->
  $rootScope.page_loaded = true

  token = Cookies.getCookie('csrftoken')
  form = document.getElementById('upload_students')
  input = document.createElement('input')
  input.type = 'hidden'
  input.name = 'csrfmiddlewaretoken'
  input.value = token
  form.appendChild(input)

  sendXLS = (e) ->
      file = document.getElementById("id_xls_file").files[0]
      if !file || file.type != "application/vnd.ms-excel"
        $scope.error_msg = "please use .xls format"
        $scope.$apply()
        e.preventDefault()
      else
          $scope.error_msg = false
          $scope.$apply()
          form.submit()

  form.addEventListener("submit", sendXLS, false);
