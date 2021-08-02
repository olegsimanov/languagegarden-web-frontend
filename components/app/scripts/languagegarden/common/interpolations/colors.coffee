    'use strict'

    {parseColor} = require('./../utils')
    {linearInterpolateValue} = require('./base')


    interpolateColorFactory = (redInterpolator, greenInterpolator,
                               blueInterpolator, alphaInterpolator) ->
        (a, b) ->
            startValues = parseColor(a)
            endValues = parseColor(b)
            appliedRedInter = redInterpolator(startValues.r, endValues.r)
            appliedGreenInter = greenInterpolator(startValues.g, endValues.g)
            appliedBlueInter = blueInterpolator(startValues.b, endValues.b)
            round = Math.round
            if startValues.a? or endValues.a?
                startAlphaVal = if startValues.a? then startValues.a else 1.0
                endAlphaVal = if endValues.a? then endValues.a else 1.0
                appliedAlphaInter = alphaInterpolator(startAlphaVal, endAlphaVal)
                (t) ->
                    "rgba(#{round(appliedRedInter(t))}, #{round(appliedGreenInter(t))}, #{round(appliedBlueInter(t))}, #{appliedAlphaInter(t)})"
            else
                (t) ->
                    "rgb(#{round(appliedRedInter(t))}, #{round(appliedGreenInter(t))}, #{round(appliedBlueInter(t))})"

    interpolateColor = interpolateColorFactory(
        linearInterpolateValue,
        linearInterpolateValue,
        linearInterpolateValue,
        linearInterpolateValue
    )


    module.exports =
        interpolateColor: interpolateColor
