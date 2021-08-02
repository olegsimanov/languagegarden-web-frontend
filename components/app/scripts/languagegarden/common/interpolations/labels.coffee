    'use strict'

    _ = require('underscore')
    {interpolateCoord} = require('./points')
    {interpolateColor} = require('./colors')
    {lcm} = require('./../../math/numtheory')


    countEqualLabels = (oldLabels, newLabels) ->
        counter = 0
        for [ol, nl] in _.zip(oldLabels, newLabels)
            if not ol?
                break
            if not nl?
                break
            if ol != nl
                return -1
            counter += 1
        counter


    getMaxLabelSequence = (oldLabels, newLabels) ->
        # assert countEqualLabels(oldLabels, newLabels) >= 0
        if oldLabels.length > newLabels.length
            oldLabels
        else
            newLabels

    getLabelSizesPair = (oldLabels, newLabels) ->
        # assert countEqualLabels(oldLabels, newLabels) >= 0
        oldLabelSizes = []
        newLabelSizes = []
        for [ol, nl] in _.zip(oldLabels, newLabels)
            oldLabelSizes.push(if ol? then 1.0 else 0.0)
            newLabelSizes.push(if nl? then 1.0 else 0.0)
        [oldLabelSizes, newLabelSizes]

    ###
    Helper for getViewAppliedInterpolator, returns applied interpolator
    used for changing labels in letter attributes
    ###
    getLabelsAppliedInterpolator = (oldLabels, newLabels, colorPalette) ->
        oldRevLabels = oldLabels[..].reverse()
        newRevLabels = newLabels[..].reverse()
        if countEqualLabels(oldLabels, newLabels) > 0
            # labels added/removed at the end - we do the gradient proportion
            # transitions, the colors are 'coming'/'escaping' at the 'bottom'
            maxLabels = getMaxLabelSequence(oldLabels, newLabels)
            maxColors = _.map(maxLabels, colorPalette.getColorForLabel)
            colorLen = maxColors.length
            [sizes1, sizes2] = getLabelSizesPair(oldLabels, newLabels)
            appliedInters = (interpolateCoord(ss, es) for [ss, es] in _.zip(
                             sizes1, sizes2))
            data = ({color: c, size: 1} for c in maxColors)
            (t) ->
                for i in [0...colorLen]
                    data[i].size = appliedInters[i](t)
                data
        else if countEqualLabels(oldRevLabels, newRevLabels) > 0
            # labels added/removed at the beginnig - we do the gradient
            # proportion transitions, the colors are 'coming'/'escaping'
            # at the 'top'
            maxRevLabels = getMaxLabelSequence(oldRevLabels, newRevLabels)
            maxLabels = maxRevLabels[..].reverse()
            maxColors = _.map(maxLabels, colorPalette.getColorForLabel)
            colorLen = maxColors.length
            [rsizes1, rsizes2] = getLabelSizesPair(oldRevLabels, newRevLabels)
            sizes1 = rsizes1[..].reverse()
            sizes2 = rsizes2[..].reverse()
            appliedInters = (interpolateCoord(ss, es) for [ss, es] in _.zip(
                             sizes1, sizes2))
            data = ({color: c, size: 1} for c in maxColors)
            (t) ->
                for i in [0...colorLen]
                    data[i].size = appliedInters[i](t)
                data
        else if oldLabels.length <= 1 or newLabels.length <= 1
            # transitions:
            # one color / no color to one color / no color
            # many colors to one color / no color
            # one color / no color to many colors
            startColors = _.map(oldLabels, colorPalette.getColorForLabel)
            endColors = _.map(newLabels, colorPalette.getColorForLabel)
            if startColors.length <= 1 and endColors.length >= 1
                colorLen = endColors.length
                if startColors.length == 1
                    startColor = startColors[0]
                else
                    startColor = colorPalette.get('newWordColor')
                startColors = (startColor for i in [0...colorLen])
            else if endColors.length <= 1 and startColors.length >= 1
                colorLen = startColors.length
                if endColors.length == 1
                    endColor = endColors[0]
                else
                    endColor = colorPalette.get('newWordColor')
                endColors = (endColor for i in [0...colorLen])
            else # if endColors.length == 0 and startColors.length == 0
                colorLen = 1
                startColors = [colorPalette.get('newWordColor')]
                endColors = [colorPalette.get('newWordColor')]
            appliedInters = (interpolateColor(sc, ec) for [sc, ec] in _.zip(
                             startColors, endColors))
            data = ({color: null} for i in [0...colorLen])
            (t) ->
                # instead of returning the labels in the form
                # [label1] we return it in the form [{color:color1}]
                # this dict will allow us to use colors directly
                for i in [0...colorLen]
                    interpolatedColor = appliedInters[i](t)
                    data[i].color = interpolatedColor
                data
        else
            # many to many colors - gradient color replacement without
            # colors 'moving in / out'
            startColors = _.map(oldLabels, colorPalette.getColorForLabel,
                                colorPalette)
            endColors = _.map(newLabels, colorPalette.getColorForLabel,
                              colorPalette)
            colorLen = lcm(startColors.length, endColors.length)

            multiplyColors = (colors) ->
                newColors = []
                factor = colorLen / colors.length
                for color in colors
                    for i in [0...factor]
                        newColors.push(color)
                newColors

            startColors = multiplyColors(startColors)
            endColors = multiplyColors(endColors)

            appliedInters = (interpolateColor(sc, ec) for [sc, ec] in _.zip(
                             startColors, endColors))
            data = ({color: null} for i in [0...colorLen])
            (t) ->
                # instead of returning the labels in the form
                # [label1] we return it in the form [{color:color1}]
                # this dict will allow us to use colors directly
                for i in [0...colorLen]
                    interpolatedColor = appliedInters[i](t)
                    data[i].color = interpolatedColor
                data


    module.exports =
        getLabelsAppliedInterpolator: getLabelsAppliedInterpolator
