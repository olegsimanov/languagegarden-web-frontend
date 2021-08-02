    'use strict'

    __raphael = require('raphael')
    _ = require('underscore')
    settings = require('./../../settings')
    {Point} = require('./../../math/points')
    {Path} = require('./../../math/bezier')
    {
        enumerate
        isSubset
        structuralEquals
        sum
        isArabicLetter
        areLettersJoinable
        wrapLetterWithZWJ
    } = require('./../utils')
    {
        getCurvedPathString
        disableSelection
        addSVGElementClass
        removeSVGElementClass
        toggleSVGElementClass
    } = require('./../domutils')
    {BaseView} = require('./base')
    {TSpanMultiColorGradient} = require('./../svggradient')
    {CanvasLayers} = require('./../constants')



    class BaseTextPath extends BaseView

        initialize: (options={}) ->
            super
            @paper = options.paper
            @nextLetter = options.nextLetter or null
            @previousLetter = options.previousLetter or null
            @letters = options.letters or []
            @lettersLengths = options.lettersLengths or []
            @lettersStyleAttrs = options.lettersStyleAttrs or []
            @fontSize = options.fontSize or 20
            if options.path?
                @path = options.path.copy()
            else
                @path = new Path(new Point(), new Point())
            @letterGradients = null
            @transformMatrix = Raphael.matrix()
            @objectId = options.objectId
            @textXOffset = 0
            @textYOffset = null
            if options.opacity?
                @opacity = options.opacity
            else
                @opacity = null
            @_changed = {}

        removeLetterGradients: ->
            if @letterGradients?
                for gradient in @letterGradients
                    gradient?.remove()
            @letterGradients = null

        getFontSize: -> @fontSize

        getMaxLetterHeight: ->
            @fontSize * settings.fontSizeToLetterHeightMultiplier

        getTextYOffset: (invalidate=false) ->
            if invalidate or not @textYOffset?
                #TODO: why 5? investigate it.
                @textYOffset = @getMaxLetterHeight() / 5
            @textYOffset

        getPath: -> @path

        getTransformMatrix: -> @transformMatrix

        getLetters: -> @letters

        getText: -> @letters.join('')

        getLetterStyleAttrs: (index) -> @lettersStyleAttrs?[index] or {}

        getLetterLength: (index) -> @lettersLengths[index] or @fontSize

        getLettersLengths: ->
            (@getLetterLength(i) for i in [0...@letters.length])

        getPathString: ->
            ### generates SVG compliant path string ###
            getCurvedPathString(
                @path.getStartPoint(),
                @path.getControlPoints(),
                @path.getEndPoint()
            )

        getOpacity: -> @opacity

        isDebugMode: -> @parentView?.isDebugMode() or false

        isTextRTL: -> @parentView?.isTextRTL() or false

        getCanvasScale: -> @parentView?.getCanvasScale() or 1.0

        setPreviousLetter: (letter=null) ->
            if letter == @previousLetter
                return this
            @previousLetter = letter
            # For some reason we need also to update fontSize
            # and lettersStyleAttrs (TextPath).
            @_changed.letters = true
            @_changed.fontSize = true
            @_changed.span = true
            @_changed.lettersStyleAttrs = true
            @_changed.gradients = true
            this

        setNextLetter: (letter=null) ->
            if letter == @nextLetter
                return this
            @nextLetter = letter
            @_changed.letters = true
            @_changed.fontSize = true
            @_changed.span = true
            @_changed.lettersStyleAttrs = true
            @_changed.gradients = true
            this

        setLetters: (letters) ->
            if structuralEquals(@letters, letters)
                return this
            @letters = letters
            @_changed.letters = true
            @_changed.fontSize = true
            @_changed.span = true
            @_changed.lettersStyleAttrs = true
            @_changed.gradients = true
            this

        setFontSize: (fontSize) ->
            if @fontSize == fontSize
                return this
            @fontSize = fontSize
            @_changed.fontSize = true
            @_changed.span = true
            @_changed.gradients = true
            this

        setPath: (path) ->
            if @path.equals(path)
                return this
            @path.setFromPath(path)
            @_changed.path = true
            @_changed.span = true
            @_changed.gradients = true
            @_changed.controlPoints = true
            this

        setTransformMatrix: (transformMatrix) ->
            if structuralEquals(@transformMatrix, transformMatrix)
                return this
            @transformMatrix = transformMatrix.clone()
            @_changed.transformMatrix = true
            this

        setLettersStyleAttrs: (lettersStyleAttrs) ->
            if structuralEquals(@lettersStyleAttrs, lettersStyleAttrs)
                return this
            @lettersStyleAttrs = _.clone(lettersStyleAttrs)
            @_changed.lettersStyleAttrs = true
            @_changed.gradients = true
            this

        setLettersLengths: (lettersLengths) ->
            if structuralEquals(@lettersLengths, lettersLengths)
                return this
            @lettersLengths = lettersLengths
            @_changed.lettersLengths = true
            @_changed.span = true
            this

        setOpacity: (opacity) ->
            if @opacity == opacity
                return this
            @opacity = opacity
            @_changed.opacity = true
            this

        getLetterStartPathPositions: ->
            letters = @getLetters()
            numOfLetters = letters.length
            spacePerElement = @getSpaceLength()
            lengths = []
            path = @getPath()

            if @isTextRTL()
                lengthAcc = path.getLength()
                for i in [0...letters.length]
                    lengthAcc -= @getLetterLength(i)
                    lengths.push(lengthAcc)
                    lengthAcc -= spacePerElement
            else
                lengthAcc = 0
                for i in [0...letters.length]
                    lengths.push(lengthAcc)
                    lengthAcc += @getLetterLength(i)
                    lengthAcc += spacePerElement

            lengths

        getLetterPathPosition: (letterIndex, letterLengthFactor) ->
            letterLen = @getLetterLength(letterIndex)
            letterPathPos = @getLetterStartPathPositions()[letterIndex]
            letterPathPos + letterLen * letterLengthFactor

        getLetterMiddlePathPositions: ->
            letters = @getLetters()
            numOfLetters = letters.length
            fontSize = @getFontSize()
            spacePerElement = @getSpaceLength()
            lengths = []
            path = @getPath()

            if @isTextRTL()
                lengthAcc = path.getLength()
                for i in [0...letters.length]
                    letterLen = @getLetterLength(i)
                    lengths.push(lengthAcc - letterLen / 2)
                    lengthAcc -= letterLen
                    lengthAcc -= spacePerElement
            else
                lengthAcc = 0
                for i in [0...letters.length]
                    letterLen = @getLetterLength(i)
                    lengths.push(lengthAcc + letterLen / 2)
                    lengthAcc += letterLen
                    lengthAcc += spacePerElement

            lengths

        getWrappedLetter: (letter, options) ->
            wrapLetterWithZWJ(letter, options)

        getSpaceLength: ->
            pathLen = @getPath().getLength()
            textLen = sum(@getLettersLengths())
            spacesLength = pathLen - textLen
            numOfLetters = @letters.length
            if numOfLetters > 1 then spacesLength / (numOfLetters - 1) else 0

        getGradientInfos: ->
            letters = @letters
            if letters.length == 0
                return []
            fontSize = @getFontSize()
            mat = @getTransformMatrix()
            path = @getPath()

            deviation = @getMaxLetterHeight() / 2
            lengths = @getLettersLengths()
            startPathPositions = @getLetterStartPathPositions()
            pairs = _.zip(startPathPositions, lengths)
            middlePathPositions = (p[0] + p[1] * 0.5 for p in pairs)

            ptTfApplicator = Point.getTransformApplicator(mat)
            vecTfApplicator = Point.getVectorTransformApplicator(mat)
            orthoApplicator = (p) ->
                vecTfApplicator(p.normalize().mulSelf(deviation))

            middlePoints = path.getPointsAtLengths(middlePathPositions)
            # applying transformations
            for p in middlePoints
                ptTfApplicator(p)

            orthogonals = path.getOrthogonalsAtLengths(middlePathPositions)
            # applying transformations + normalization
            for v in orthogonals
                orthoApplicator(v)

            for [m, o, l] in _.zip(middlePoints, orthogonals, lengths)
                smallOrthogonal = o.mul(0.5)
                up: m.add(smallOrthogonal)
                down: m.sub(smallOrthogonal)
                bigUp: m.add(o)
                bigDown: m.sub(o)
                letterLength: l

        getLetterObj: (index) ->
            console.log('getLetterObj not implemented')
            null

        updateOpacity: ->
            console.log('updateOpacity not implemented')

        updateStyle: ->
            lettersLen = @letters.length
            if not @letterGradients?
                @letterGradients = (null for i in [0...lettersLen])
            delta = lettersLen - @letterGradients.length
            if delta > 0
                @letterGradients = @letterGradients.concat((null for i in [0...delta]))
            else if delta < 0
                gradientsToRemove = @letterGradients[lettersLen..]
                @letterGradients = @letterGradients[0...lettersLen]
                for gradient in gradientsToRemove
                    gradient?.remove()

            for i in [0...lettersLen]
                @updateLetterStyle(i)
            return

        updateLetterStyle: (letterIndex) ->
            lObj = @getLetterObj(letterIndex)
            attr = @getLetterStyleAttrs(letterIndex)
            oldGradient = @letterGradients[letterIndex]
            if attr.fill?.length == 0
                return

            if attr.fill.length == 1
                lObj.node.setAttribute('fill', attr.fill[0][0])
                oldGradient?.remove()
                @letterGradients[letterIndex] = null
            else
                # {'fill': [['#color', size1], ['#color2', size2]..]}
                # map to [{color: '#color1'}, {color: '#color2'}]
                mf = _.map attr.fill, (x) => {color: x[0], size: x[1]}
                if not structuralEquals(mf, oldGradient?.multiColor)
                    startOffset = 0.25
                    endOffset = 0.75
                    gradient = new TSpanMultiColorGradient
                        paper: @paper
                        multiColor: mf
                        useFullSize: true
                        startOffset: startOffset
                        endOffset: endOffset
                    gradient.applyOnElement(lObj)
                    oldGradient?.remove()
                    @letterGradients[letterIndex] = gradient

        updateGradients: ->
            if not @letterGradients?
                return
            mat = @getTransformMatrix()
            invMat = mat.invert()
            lettersLen = @letters.length
            lettersRange = [0...lettersLen]
            if _.some(@letterGradients, (x) => x?)
                gradientInfos = @getGradientInfos()
            else
                gradientInfos = (null for i in lettersRange)

            for i in lettersRange
                gradient = @letterGradients[i]
                info = gradientInfos[i]
                letter = @letters[i]

                if gradient?
                    options =
                        x1: info.bigUp.x
                        y1: info.bigUp.y
                        x2: info.bigDown.x
                        y2: info.bigDown.y
                        letterLength: info.letterLength
                        letter: letter
                        gradientTransform: invMat.toString()
                        transformMatrix: mat  # additonal info
                        invTransformMatrix: invMat  # additonal info
                        textYOffset: @getTextYOffset()
                        canvasScale: @getCanvasScale()
                    gradient.update(options)

        updateTransform: ->
            matrix = @getTransformMatrix()
            @applyTransformMatrix(matrix)

        updatePath: ->
            console.log('updatePath not implemented')

        updateLetters: ->
            console.log('updateLetters not implemented')

        updateSpan: ->
            console.log('updateSpan not implemented')

        updateFontSize: ->
            console.log('updateSpan not implemented')

        updateEachTime: ->

        update: ->
            changed = @_changed
            if changed.letters
                @updateLetters()
                changed.letters = false
            if changed.transformMatrix
                @updateTransform()
                changed.transformMatrix = false
            if changed.path
                @updatePath()
                changed.path = false
            if changed.fontSize
                @updateFontSize()
                changed.fontSize = false
            if changed.span
                @updateSpan()
                changed.span = false
            if changed.lettersStyleAttrs
                @updateStyle()
                changed.lettersStyleAttrs = false
            if changed.gradients
                @updateGradients()
                changed.gradients = false
            if changed.opacity
                @updateOpacity()
                changed.opacity = false

            @updateEachTime()

        reCreate: ->
            @remove()
            @create()


    class TextPath extends BaseTextPath

        initialize: (options) ->
            super
            @tpObj = null

        getLetterObj: (index) -> @tpObj.letters?[index]

        disableSelection: ->
            letterObjs = @tpObj.letters
            nodes = (letterObj.node for letterObj in letterObjs)
            nodes = nodes.concat([@tpObj.node])
            for node in nodes
                disableSelection(node)

        addCSSClass: (className) ->
            addSVGElementClass(@tpObj.node, className)

        removeCSSClass: (className) ->
            removeSVGElementClass(@tpObj.node, className)

        toggleCSSClass: (className, flag, letters=false) ->
            toggleSVGElementClass(@tpObj.node, className, flag)
            if letters
                for i in [0...@getLetters().length]
                    toggleSVGElementClass(@tpObj.letters[i].node, className,
                                          flag)
            return

        updateOpacity: ->
            @tpObj?.attr('opacity', @opacity)

        updateTransformMatrix: ->
            if not @tpObj?
                return
            @tpObj.attr
                transform: @transformMatrix.toTransformString()

        updateSpan: ->
            letters = @letters
            spaceLen = @getSpaceLength()
            letterObjs = @tpObj.letters

            for i in [1...letters.length]
                letterObj = letterObjs[i]
                letterObj.node.setAttribute('dx', spaceLen)

        applyTransformMatrix: (matrix) ->
            @tpObj.transform(matrix.toTransformString()) if matrix?

        updateFontSize: ->
            letterObjs = @tpObj.letters
            fontSize = @getFontSize()
            for letterObj in letterObjs
                letterObj.node.setAttribute('font-size', fontSize)
            # for the first letter only
            letterObjs[0].node.setAttribute('dy', @getTextYOffset(true))

        # updaters below are more high level and check if @tpObj is defined

        updatePath: ->
            if @tpObj?
                # using raw DOM call instead of
                # @tpObj.updatePath(@getPathString()) to make is as fast
                # as possible
                @tpObj.path.node.setAttribute('d', @getPathString())

        setCoreOpacity: (opacity) -> @tpObj?.attr('opacity', opacity)

        toFront: ->
            if not @parentView?
                return
            if not @tpObj?
                return
            @parentView.putElementToFrontAtLayer(@tpObj, CanvasLayers.LETTERS)

        updateLetters: () ->
            @tpObj.updateText(@getText())
            @disableSelection()

        create: ->
            # assert not @tpObj?
            showPath = @isDebugMode() and settings.debug.showPath

            startOffset = 0

            @tpObj = @paper.textPath(
                @getPathString(),
                @getText(),
                @textXOffset,
                @getTextYOffset(),
                startOffset,
                'center',
                showPath
            )
            @tpObj.node.setAttribute('data-object-id', @objectId)

            @updateTransformMatrix()
            @updateFontSize()
            @updateSpan()
            @updateStyle()
            @updateGradients()
            @updateOpacity()
            @disableSelection()

            debugMode = @isDebugMode()

            if debugMode and settings.debug.showPath
                @paper.add(@tpObj.path)
                @tpObj.path.attr("stroke": Raphael.getColor())

            @updateEachTime()

        remove: ->
            if @tpObj?
                @tpObj.path.remove()
                @tpObj.remove()
                @tpObj = null
            @removeLetterGradients()
            super


    class SyntheticTextPath extends BaseTextPath
        ### Workaround which uses SVG texts for each letter ###

        initialize: (options) ->
            super
            @textObjs = null
            @upAngleRad = Math.atan2(0, -1)
            @radToDegFactor = 180 / Math.PI

        getLetterObjs: -> @textObjs or []

        getLetterObj: (index) -> @getLetterObjs()[index]

        getLetterNodes: -> (letterObj.node for letterObj in @getLetterObjs() when letterObj?.node?)

        disableSelection: ->
            for node in @getLetterNodes()
                disableSelection(node)
            return this

        addCSSClass: (className) ->
            for node in @getLetterNodes()
                addSVGElementClass(node, className)
            return this

        removeCSSClass: (className) ->
            for node in @getLetterNodes()
                removeSVGElementClass(node, className)
            return this

        toggleCSSClass: (className, flag, letters=false) ->
            for node in @getLetterNodes()
                toggleSVGElementClass(node, className, flag)
            return this

        updateOpacity: ->
            opacity = @opacity
            for letterObj in @getLetterObjs()
                letterObj.attr('opacity', opacity)
            return this

        updateTransformMatrix: ->
            if not @textObjs?
                return this
            for letterObj in @getLetterObjs()
                letterObj.attr
                    transform: @transformMatrix.toTransformString()
            return this

        updateSpan: ->
            middlePathPositions = @getLetterMiddlePathPositions()
            points = @path.getPointsAtLengths(middlePathPositions)
            orthogonals = @path.getOrthogonalsAtLengths(middlePathPositions)
            upAngleRad = @upAngleRad
            radToDegFactor = @radToDegFactor

            for i in [0...@letters.length]
                p = points[i]
                letterObj = @textObjs[i]
                angleRad = Math.atan2(orthogonals[i].x, orthogonals[i].y)
                deviationAngleDeg = (upAngleRad - angleRad) * radToDegFactor
                mat = Raphael.matrix()
                mat.rotate(deviationAngleDeg, p.x, p.y)
                @lettersTransforms[i] = mat
                letterObj.attr(p)
                letterObj.attr('transform', mat.toTransformString())

            return this

        applyTransformMatrix: (matrix) ->
            if not matrix?
                return this
            for i in [0...@letters.length]
                letterObj = @textObjs[i]
                letterTransform = @lettersTransforms[i]
                letterMat = Raphael.matrix()
                letterMat.add(matrix)
                letterMat.add(letterTransform)
                letterObj.transform(letterMat.toTransformString())
            return this


        updateFontSize: ->
            fontSize = @getFontSize()
            for letterObj in @getLetterObjs()
                letterObj.attr('font-size', fontSize)
            return this

        # updaters below are more high level and check if @tpObj is defined

        updatePath: ->
            # positioning is handled by updateSpan
            return this

        toFront: ->
            if not @textObjs?
                return
            if not @parentView?
                return
            for letterObj in @getLetterObjs()
                @parentView.putElementToFrontAtLayer(
                    letterObj,
                    CanvasLayers.LETTERS
                )
            return this

        updateLetters: ->
            @textObjs ?= []
            @lettersTransforms ?= []
            letters = @letters
            lettersLen = letters.length
            delta = lettersLen - @textObjs.length
            if delta > 0
                @textObjs = @textObjs.concat((null for i in [0...delta]))
                @lettersTransforms = @lettersTransforms.concat((Raphael.matrix() for i in [0...delta]))
            else if delta < 0
                letterObjsToRemove = @textObjs[lettersLen..]
                @textObjs = @textObjs[0...lettersLen]
                @lettersTransforms[0...lettersLen]
                for letterObj in letterObjsToRemove
                    letterObj?.remove()

            opts = {}

            for i in [0...lettersLen]
                if i == 0
                    opts.previousLetter = @previousLetter
                else
                    opts.previousLetter = letters[i - 1]
                if i == lettersLen - 1
                    opts.nextLetter = @nextLetter
                else
                    opts.nextLetter = letters[i + 1]
                wrappedLetter = @getWrappedLetter(letters[i], opts)
                if @textObjs[i]?
                    @textObjs[i].attr('text', wrappedLetter)
                else
                    textObj = @textObjs[i] = @paper.text(0, 0, wrappedLetter)
                    # Raphael.js by default adds the Arial font. WTF Raphael?
                    textObj.node.removeAttribute('font')
                    textObj.node.style['font-family'] = ''

            for node in @getLetterNodes()
                node.setAttribute('data-object-id', @objectId)
            @disableSelection()

        updateEachTime: ->
            # HACK:
            # because Raphael wrongly calculates the
            # dy for inner tspan, we need to update it each time
            # WTF...
            for node in @getLetterNodes()
                tspan = node?.childNodes[0]
                tspan.setAttribute('dy', @getTextYOffset(true))
            return this


        create: ->
            # assert not @textObjs?
            @updateLetters()

            @updateTransformMatrix()
            @updateFontSize()
            @updateSpan()
            @updateStyle()
            @updateGradients()
            @updateOpacity()
            @updateEachTime()

        remove: ->
            for letterObj in @getLetterObjs()
                letterObj.remove()
            @textObjs = null
            @removeLetterGradients()
            super


    module.exports =
        TextPath: TextPath
        SyntheticTextPath: SyntheticTextPath
