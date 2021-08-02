angular.module('lgLessons').filter 'cut', () ->
  return (value, wordwise, max, tail) ->
    return '' if !value

    max = parseInt(max, 10)

    return value unless max
    return value if value.length <= max

    value = value.substr(0, max)

    if wordwise
      lastspace = value.lastIndexOf(' ')
      if lastspace != -1
        value = value.substr(0, lastspace)

    return value + (tail || '…')
