    'use strict'

    _ = require('underscore')
    {linearInterpolateValue} = require('./base')


    interpolateAngleFactory = (angleStart, angleEnd, baseInterpolator) ->
        angleRange = [angleStart, angleEnd]
        angleStart = _.min(angleRange)
        angleEnd = _.max(angleRange)
        fullAngle = angleEnd - angleStart
        (a, b) ->
            difference = Math.abs(b - a)
            differenceThroughAngleStart = Math.abs(a - angleStart) + Math.abs(angleEnd - b)
            differenceThroughAngleEnd = Math.abs(angleEnd - a) + Math.abs(b - angleStart)
            minDifference = _.min([difference, differenceThroughAngleStart, differenceThroughAngleEnd])

            if minDifference == difference
                # use the usual
                baseInterpolator(a, b)

            else if minDifference == differenceThroughAngleEnd
                # interpolate a -> angle end -> b
                appliedInter = baseInterpolator(a, b + fullAngle)
                (t) ->
                    x = appliedInter(t)
                    if x >= angleEnd then x - fullAngle else x

            else  # if minDifference == differenceThroughAngleStart
                # interpolate through a -> angle start -> b
                appliedInter = baseInterpolator(a + fullAngle, b)
                (t) ->
                    x = appliedInter(t)
                    if x >= angleEnd then x - fullAngle else x


    interpolateDegree = interpolateAngleFactory(-180, 180,
                                                linearInterpolateValue)


    module.exports =
        interpolateDegree: interpolateDegree
