angular.module('lgLessons').service 'Cookies', (
) ->
  @getCookie = (name) ->
    cookieValue = null
    if document.cookie and document.cookie != ''
      cookies = document.cookie.split(';')
      i = 0
      while i < cookies.length
        cookie = cookies[i].trim()
        if cookie.substring(0, name.length + 1) == name + '='
          cookieValue = cookie.substring(name.length + 1)
          break
        i++
    if !cookieValue and name == 'csrftoken'
      input = document.getElementsByName('csrfmiddlewaretoken')[0]
      cookieValue = input.value
    cookieValue

  return @