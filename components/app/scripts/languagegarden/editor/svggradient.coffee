    'use strict'

    require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    require('jquery.browser')
    {Point} = require('./../math/points')
    {SVGWrappedElement} = require('./svgbase')
    {
        addSVGElementClass
        removeSVGElementClass
    } = require('./domutils')


    class Gradient extends SVGWrappedElement

        generateId: -> _.uniqueId('lg-gradient-uniq-')

        getParentNode: -> @getSVGDefsNode()

        applyOnElement: (element) ->
            element.node.setAttribute('fill', @getAttrRef())


    class LinearGradient extends Gradient

        initialize: (options) ->
            super
            @colorInfos = options.colorInfos
            setDefault = (name, _default) =>
                @[name] = if options[name]? then options[name] else _default
            setDefault('x1', '0%')
            setDefault('y1', '0%')
            setDefault('x2', '0%')
            setDefault('y2', '100%')
            setDefault('gradientUnits', 'userSpaceOnUse')
            setDefault('gradientTransform', Raphael.matrix().toString())

        updatePropertiesHelper: (propNames, options) ->
            for propName in propNames
                @[propName] = options[propName] if options[propName]?
            return

        updateProperties: (options) ->
            super
            propNames = ['x1', 'y1', 'x2', 'y2',
                         'gradientTransform', 'gradientUnits']
            @updatePropertiesHelper(propNames, options)

        generateId: -> _.uniqueId('lg-linear-gradient-uniq-')

        createSVGNode: (svgNS) ->
            node = document.createElementNS(svgNS, 'linearGradient');
            for ci in @colorInfos
                stop = document.createElementNS(svgNS, 'stop');
                stop.setAttribute('stop-color', ci.color)
                stop.setAttribute('offset', "#{Math.round(ci.offset*100)}%")
                node.appendChild(stop)
            node

        updateSVGNode: (node) ->
            node.setAttribute('x1', @x1)
            node.setAttribute('y1', @y1)
            node.setAttribute('x2', @x2)
            node.setAttribute('y2', @y2)
            node.setAttribute('gradientUnits', @gradientUnits)
            node.setAttribute('gradientTransform', @gradientTransform)


    class MultiColorGradient extends LinearGradient

        initialize: (options={}) ->
            startOffset = options.startOffset or 0.0
            endOffset = options.endOffset or 1.0
            offsetDelta = endOffset - startOffset
            useFullSize = options.useFullSize
            useFullSize ?= false
            multiColor = options.multiColor
            multiColorSizes = ((if mc.size? then mc.size else 1.0) for mc in multiColor)
            multiColorTotalSize = 0
            for size in multiColorSizes
                multiColorTotalSize += size
            offsetIncreases = (offsetDelta * size / multiColorTotalSize for size in multiColorSizes)
            if useFullSize
                # use the sizes in range [0, 1], the startOffset & endOffset
                # are distributed according to the size
                currentOffset = 0

                distributeOffsetDelta = (offsetDelta, indices) ->
                    offsetIncToDistribute = offsetDelta
                    for i in indices
                        if offsetIncToDistribute <= 0.0
                            break
                        size = multiColorSizes[i]
                        offsetIncToAdd = _.min([offsetDelta * size,
                                               offsetIncToDistribute])
                        offsetIncreases[i] += offsetIncToAdd
                        offsetIncToDistribute -= offsetIncToAdd

                distributeOffsetDelta(startOffset,
                                      [0...multiColorSizes.length])
                distributeOffsetDelta(1.0 - endOffset,
                                      [0...multiColorSizes.length].reverse())
            else
                currentOffset = startOffset
            colorInfos = []

            for [mc, offsetIncrease] in _.zip(multiColor, offsetIncreases)
                colorInfos.push
                    color: mc.color
                    offset: currentOffset
                currentOffset += offsetIncrease
                colorInfos.push
                    color: mc.color
                    offset: currentOffset

            options.colorInfos = colorInfos
            super(options)
            @multiColor = multiColor


    class WebkitShiftedMultiColorGradient extends MultiColorGradient

        initialize: (options) ->
            @textYOffset = 0
            @transformMatrix = Raphael.matrix()
            @invTransformMatrix = Raphael.matrix()
            @appliedElements = []
            @canvasScale = 1
            super

        updateProperties: (options) ->
            super
            propNames = [
                'textYOffset', 'transformMatrix', 'invTransformMatrix',
                'canvasScale',
            ]
            @updatePropertiesHelper(propNames, options)

            PI = Math.PI
            upAngleRad = Math.atan2(0, 1)
            radToDegFactor = 180 / PI

            x1 = if typeof @x1 == 'number' then @x1 else 0
            y1 = if typeof @y1 == 'number' then @y1 else 0
            x2 = if typeof @x2 == 'number' then @x2 else 0
            y2 = if typeof @y2 == 'number' then @y2 else 1

            gradientAngleRad = Math.atan2(x2 - x1, y2 - y1)
            deviationAngleDeg = (gradientAngleRad - upAngleRad) * radToDegFactor
            split = @transformMatrix.split()
            mat = Raphael.matrix()

            # Don't ask me why following sequence of transformation works.
            # I have no idea.
            mat.translate(0, -@textYOffset)
            mat.scale(@canvasScale)
            mat.scale(1, 1 / @canvasScale)
            mat.rotate(deviationAngleDeg, (x2 + x1) / 2, (y2 + y1) / 2)
            mat.scale(1.0 / @canvasScale)

            @gradientTransform = mat.toString()

        applyOnElement: (element) ->
            super
            @appliedElements.push(element)

        update: (options) ->
            super
            for elem in @appliedElements
                # hack used for redrawing gradient
                addSVGElementClass(elem.node, 'forced-redraw')
                removeSVGElementClass(elem.node, 'forced-redraw')
            this

        remove: ->
            @appliedElements = []
            super


    if $.browser.webkit
        ChosenMultiColorGradient = WebkitShiftedMultiColorGradient
    else
        ChosenMultiColorGradient = MultiColorGradient


    module.exports =
        TSpanMultiColorGradient: ChosenMultiColorGradient
        MultiColorGradient: ChosenMultiColorGradient
