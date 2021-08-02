    'use strict'



    linearInterpolateValue = (a, b) ->
        (t) -> (1.0 - t) * a + t * b

    exponentialInterpolateValueFactory = (base, squeeze) ->
        endExpVal = Math.pow(base, -squeeze)
        startExpVal = 1
        scale = 1 / (startExpVal - endExpVal)
        (a, b) ->
            diff = b - a
            factor = diff * scale
            (t) -> a + (1.0 - Math.pow(base, -t * squeeze)) * factor

    exponentialInterpolateValue = exponentialInterpolateValueFactory(2, 8)

    stepInterpolateValueFactory = (stepPoint) ->
        (a, b) ->
            (t) -> if t < stepPoint then a else b

    stepInterpolateValue = stepInterpolateValueFactory(0.5)

    immediateStepInterpolateValue = stepInterpolateValueFactory(0.0001)

    arrayInterpolator = (values) -> (t) -> values[Math.floor(t * values.length)]


    module.exports =
        linearInterpolateValue: linearInterpolateValue
        exponentialInterpolateValue: exponentialInterpolateValue
        stepInterpolateValue: stepInterpolateValue
        immediateStepInterpolateValue: immediateStepInterpolateValue
        arrayInterpolator: arrayInterpolator

        interpolateOpacity: exponentialInterpolateValue
        interpolateValue: linearInterpolateValue
        interpolateNumber: linearInterpolateValue

