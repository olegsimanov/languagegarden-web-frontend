    'use strict'

    {Point} = require('./../../math/points')
    {exponentialInterpolateValue} = require('./base')


    interpolatePointFactory = (xInterpolator, yInterpolator, reuseObj=true) ->
        (a, b) ->
            appliedXInter = xInterpolator(a.x, b.x)
            appliedYInter = yInterpolator(a.y, b.y)
            if reuseObj
                reusableObj = new Point()
                (t) ->
                    reusableObj.x = appliedXInter(t)
                    reusableObj.y = appliedYInter(t)
                    reusableObj
            else
                (t) -> new Point(appliedXInter(t), appliedYInter(t))

    interpolatePoint = interpolatePointFactory(
        exponentialInterpolateValue,
        exponentialInterpolateValue,
        exponentialInterpolateValue,
        exponentialInterpolateValue
    )


    module.exports =
        interpolatePointFactory: interpolatePointFactory
        interpolateCoord: exponentialInterpolateValue
        interpolatePoint: interpolatePoint
