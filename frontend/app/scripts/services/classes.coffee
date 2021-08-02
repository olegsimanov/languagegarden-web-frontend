angular.module('lgLessons').service 'Classes', (
  $http
  baseApiUrl
) ->

  @get = () ->
    $http.get "#{baseApiUrl}classes/", params: page_size: 9999


  @create = (data) ->
    $http.post "#{baseApiUrl}classes/", data


  @update = (classId, data) ->
    $http
      method: "patch"
      url: "#{baseApiUrl}classes/#{classId}/"
      data: data


  @remove = (classId) ->
    $http.delete "#{baseApiUrl}classes/#{classId}/"


  @addLesson = (classId, lessonId) ->
    $http.post "#{baseApiUrl}classes/#{classId}/add_lesson/", lesson_id: lessonId


  @removeLesson = (classId, lessonId) ->
    $http.post "#{baseApiUrl}classes/#{classId}/remove_lesson/", lesson_id: lessonId


  return @
