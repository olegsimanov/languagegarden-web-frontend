    'use strict'

    Raphael = require('raphael')
    _ = require('underscore')

    {Point}                 = require('./../../math/points')
    {AffineTransformation}  = require('./../../math/transformations')
    {Path}                  = require('./../../math/bezier')
    settings                = require('./../../settings')
    {deepCopy}              = require('./../utils')
    {PlantChildModel, PlantChildCollection} = require('./base')


    ATF = AffineTransformation
    collectionIdName = 'id'


    class PlantElement extends PlantChildModel

        collectionIdName: collectionIdName

        letterStyleAttributes: ['labels']

        constructor: (options) ->
            @path = new Path(new Point(), new Point())
            super

        initialize: (options) ->
            super
            setDefaultValue = (name, value) =>
                @set(name, value) if not @get(name)?
            setDefaultValue('startPoint', new Point(0,0))
            setDefaultValue('endPoint', @get('startPoint'))
            setDefaultValue('controlPoints', [])
            setDefaultValue('text', '')
            setDefaultValue('transformMatrix', Raphael.matrix())

            if options?.transformMatrix?
                scale = options.transformMatrix.split?().scalex
                if scale? and scale != 1
                    @reduceTransform()

            lettersAttributes = (
                @getDefaultLetterAttrs(options) for i in _.range(
                    @get('text').length))
            setDefaultValue('lettersAttributes', lettersAttributes)

        getDefaultLetterAttrs: (options) =>
            attrs = {}
            attrs['labels'] = []
            attrs

        setLetterAttribute: (letters, key, value, options) ->

            if not letters?
                indexes = [0...@get('text').length]
            else if _.isNumber(letters)
                indexes = [letters]
            else if _.isArray(letters)
                indexes = letters
            else
                return
            lettersAttributes = @get('lettersAttributes')
            loud = not (options? and options.silent)
            changeLetterStyle = false
            changeLetterKey = false
            keyIsInStyle = key in @letterStyleAttributes

            for index in indexes
                lettersAttributes[index] ?= {}
                letterAttrs = lettersAttributes[index]
                if letterAttrs[key] != value
                    letterAttrs[key] = value
                    changeLetterKey = true
                    @trigger("change:letter:#{key}:#{index}") if loud
                    if keyIsInStyle
                        changeLetterStyle = true

            if changeLetterKey
                @trigger("change:letter:#{key}") if loud
                @trigger("change", this) if loud
            if changeLetterStyle
                @trigger("change:letter:style") if loud

        getLetterAttribute: (letterIndex, key) ->
            lettersAttributes = @get('lettersAttributes')
            letterAttrs = lettersAttributes[letterIndex]
            letterAttrs[key] if key? and letterAttrs?

        get: (key) ->
            if key == 'path'
                @path
            else if key == 'points'
                @getPoints()
            else
                super

        set: (key, val, options) ->
            if typeof key == 'object'
                attrs = _.clone(key) or {}
                options = val
            else
                attrs = {}
                attrs[key] = val

            pathChanged = false

            if attrs.path?
                attrs.startPoint = attrs.path.getStartPoint()
                attrs.endPoint = attrs.path.getEndPoint()
                attrs.controlPoints = attrs.path.getControlPoints()
                delete attrs.path

            if attrs.points?
                [attrs.startPoint, attrs.controlPoints...,
                 attrs.endPoint] = attrs.points
                delete attrs.points

            for name in ['startPoint', 'endPoint']
                if attrs[name]?
                    attrs[name] = Point.fromValue(attrs[name])
                    if not @path[name].equals(attrs[name])
                        pathChanged = true
                    @path[name] = attrs[name]

            for name in ['controlPoints']
                if attrs[name]?
                    attrs[name] = (Point.fromValue(p) for p in attrs[name])
                    if not _.isEqual(@path[name], attrs[name])
                        pathChanged = true
                    @path[name] = attrs[name]

            for name in ['transformMatrix']
                if attrs[name]?
                    m = attrs[name]
                    attrs[name] = Raphael.matrix(m.a, m.b, m.c, m.d, m.e, m.f)

            for name in ['lettersAttributes']
                if attrs[name]?
                    attrs[name] = deepCopy(attrs[name])

            for name in ['text']
                if attrs[name]?
                    newText = attrs[name]
                    oldText = @get(name) or ''
                    lenDelta = newText.length - oldText.length
                    if lenDelta != 0 and options?['caretPositions']?
                        lettersAttributes = @get('lettersAttributes')
                        caretPositions = options.caretPositions
                        if lenDelta > 0  # insertion
                            start = caretPositions.current - lenDelta
                            protoIndex = if start > 0 then start - 1 else 0
                            letterStyle = @getDefaultLetterAttrs(options)
                            if lettersAttributes[protoIndex]?
                                protoLetterAttrs = lettersAttributes[protoIndex]
                            else
                                protoLetterAttrs = @getDefaultLetterAttrs(options)
                            inserts = (
                                _.clone(protoLetterAttrs) for i in [0...lenDelta])
                            firstCut = lettersAttributes[0...start]
                            secondCut = lettersAttributes[start..]
                            lettersAttributes = firstCut.concat(inserts).concat(secondCut)
                        else if lenDelta < 0  # deletion
                            end = caretPositions.current
                            start = caretPositions.current - lenDelta
                            firstCut = lettersAttributes[0...end]
                            secondCut = lettersAttributes[start..]
                            lettersAttributes = firstCut.concat(secondCut)
                        attrs['lettersAttributes'] = lettersAttributes

            if pathChanged
                @path.invalidateCache()

            result = super(attrs, options)

            if pathChanged and not options?.silent
                @trigger('change:path', this, @path)

            result

        getFastAttributeSetter: (attr) ->
            if attr in ['startPoint', 'endPoint', 'controlPoints']
                (value) =>
                    @attributes[attr] = value
                    @changed[attr] = value
                    @path[attr] = value
                    @path.invalidateCache()
            else
                super

        getFastAttributeLevel1Setter: (attr, level1) ->
            if attr in ['startPoint', 'endPoint', 'controlPoints']
                (value) =>
                    @attributes[attr][level1] = value
                    @changed[attr] = @attributes[attr]
                    @path.invalidateCache()
            else
                super

        getFastAttributeLevel2Setter: (attr, level1, level2) ->
            if attr in ['startPoint', 'endPoint', 'controlPoints']
                (value) =>
                    @attributes[attr][level1][level2] = value
                    @changed[attr] = @attributes[attr]
                    @path.invalidateCache()
            else
                super

        toJSON: =>
            data = super()

            # dumping Point objects to ordinary object
            for name in ['startPoint', 'endPoint']
                data[name] = data[name].toJSON()

            # dumping Point array to array of ordinary objects
            for name in ['controlPoints']
                data[name] = (p.toJSON() for p in data[name])

            # dumping Raphael matrix to ordinary object
            for name in ['transformMatrix']
                m = data[name]
                data[name] =
                    a: m.a
                    b: m.b
                    c: m.c
                    d: m.d
                    e: m.e
                    f: m.f

            # defensive deep copying of array of letter atributes
            for name in ['lettersAttributes']
                data[name] = deepCopy(data[name])

            data

        convertPointToPathCoordinates: (screenPoint) ->
            transform = Point.getTransform(@get('transformMatrix').invert())
            transform(screenPoint)

        convertPointToScreenCoordinates: (pathPoint) ->
            transform = Point.getTransform(@get('transformMatrix'))
            transform(pathPoint)

        getPoints: ->
            [@get('startPoint')]
            .concat(@get('controlPoints'))
            .concat([@get('endPoint')])

        getPointsCopy: -> p.copy() for p in @getPoints()

        getPath: -> @path

        reduceTransform: ->
            fontSize = @get('fontSize')
            mat = @get('transformMatrix')
            matInfo = mat.split()
            matTransformApp = Point.getTransformApplicator(mat)

            # we trasform all the points to the screen coordinates...
            points = @getPointsCopy()
            for p in points
                matTransformApp(p)
            # ...then reset the matrix
            mat.a = 1
            mat.b = 0
            mat.c = 0
            mat.d = 1
            mat.e = 0
            mat.f = 0
            # ... and scale the font size properly
            @set
                fontSize: fontSize * matInfo.scalex
                points: points

        calculateScalingRotation: (originPoint, inputVector, outputVector,
                                   options) ->
            fontSize = @get('fontSize')
            scaleFactor = outputVector.getNorm() / inputVector.getNorm()

            if options?.limit
                newScaleFactor = null
                if scaleFactor < settings.minFontSize / fontSize
                    newScaleFactor = settings.minFontSize / fontSize
                if scaleFactor > settings.maxFontSize / fontSize
                    newScaleFactor = settings.maxFontSize / fontSize
                if newScaleFactor?
                    outputVector.mulSelf(newScaleFactor / scaleFactor)
                    scaleFactor = newScaleFactor

            ATF.scalingRotation(originPoint, inputVector, outputVector, options)

        transform: (t, source) ->
            # In our case, when the transformation is composed
            # of uniform scaling and rotation, the square root
            # of the determinant is the scaling factor.
            scaleFactor = Math.sqrt(t.getDeterminant())

            source ?= this

            attrs = {}
            attrs.controlPoints = (
                t.getTransformedPoint(p) for p in source.get('controlPoints'))
            attrs.endPoint = t.getTransformedPoint(source.get('endPoint'))
            attrs.startPoint = t.getTransformedPoint(source.get('startPoint'))
            attrs.fontSize = scaleFactor * source.get('fontSize')

            @set(attrs)

        stretch: (stretchPoint, startLetterStretched=false, options) ->
            text = @get('text')
            fontSize = @get('fontSize')
            path = @getPath()

            if startLetterStretched
                originPoint = @get('endPoint')
                oldStretchPoint = @get('startPoint')
            else
                originPoint = @get('startPoint')
                oldStretchPoint = @get('endPoint')

            if options?.limit
                minPathLen = options?.minPathLen
                minPathLen ?= fontSize * 0.35 * text.length
                pathLen = path.getLength()
                vecLen = Point.getDistance(originPoint, oldStretchPoint)
                minVecLen = (minPathLen / pathLen) * vecLen
                stretchVector = stretchPoint.sub(originPoint)
                newVecLen = stretchVector.getNorm()

                if vecLen < minVecLen
                    # this is for avoiding the "jump"
                    minVecLen = vecLen

                if newVecLen < minVecLen
                    stretchPoint = originPoint.addMul(stretchVector, minVecLen / newVecLen)

            attrs = {}
            controlPoints = @get('controlPoints')

            # simple case - calculate the point between boundary points
            if text.length == 2
                step = 1 / (controlPoints.length + 1)

                attrs.controlPoints = (Point.getPointBetween(
                    originPoint, stretchPoint, step * (i + 1)
                ) for i in [0...controlPoints.length])

            # regular case
            if text.length > 2
                inputVector = oldStretchPoint.sub(originPoint)
                outputVector = stretchPoint.sub(originPoint)
                t = ATF.scalingRotation(originPoint, inputVector, outputVector)
                attrs.controlPoints = (t.getTransformedPoint(p) for p in controlPoints)

            attrPrefix = if startLetterStretched then 'start' else 'end'
            attrs["#{attrPrefix}Point"] = stretchPoint
            @set(attrs)


    class PlantElements extends PlantChildCollection
        model: PlantElement
        objectIdPrefix: 'element'


    module.exports =
        PlantElement:   PlantElement
        PlantElements:  PlantElements
