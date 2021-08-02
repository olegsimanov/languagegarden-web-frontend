angular.module('lgLessons').controller 'UnsupportedBrowserCtrl', (
  $scope
  ipCookie
) ->

  cookieKey = 'do_not_show_old_browser_notification'

  chromeMatch = window.navigator.appVersion.match(/Chrome\/(\d+)\./)
  safariMatch = window.navigator.appVersion.match(/AppleWebKit\/(\d+)\./)
  isSupportedBrowser = ((chromeMatch and parseInt(chromeMatch[1], 10) >= 30) or
    (safariMatch and parseInt(safariMatch[1], 10) >= 530))

  unless isSupportedBrowser or ipCookie(cookieKey)
    $scope.show_outdated_browser_msg = true

  $scope.hideMsg = () ->
    $scope.show_outdated_browser_msg = false
    ipCookie(cookieKey, true, path: '/')
