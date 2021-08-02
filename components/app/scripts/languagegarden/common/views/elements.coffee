    'use strict'

    Hammer = require('hammerjs')
    _ = require('underscore')
    $ = require('jquery')
    require('jquery.browser')
    settings = require('./../../settings')
    {Point} = require('./../../math/points')
    {BBox} = require('./../../math/bboxes')
    {
        enumerate
        isSubset
        structuralEquals
        sum
        wrapLetterWithZWJ
    } = require('./../utils')
    {
        getCurvedPathString
        disableSelection
        addSVGElementClass
        toggleSVGElementClass
    } = require('./../domutils')
    {LetterMetrics} = require('./../svgmetrics')
    {TSpanMultiColorGradient} = require('./../svggradient')
    {exponentialInterpolateValue} = require('./../interpolations/base')
    {Animation} = require('./../animations/animations')
    {getAnimations} = require('./../animations/utils')
    {splitDiff} = require('./../diffs/utils')
    {
        getLetterAreaPathStringAndPoints
        getBigUpperPath
        getBigLowerPath
        getSmallUpperPath
        getSmallLowerPath
    } = require('./../letterareas')
    {VisibilityType, CanvasLayers} = require('./../constants')
    {PlantChildView} = require('./base')
    {TextPath, SyntheticTextPath} = require('./textpaths')


    class ElementView extends PlantChildView

        initialize: (options) =>
            super(options)
            @paper = options.paper or @parentView?.paper
            @textPath = null
            @letterAreas = []
            letterAreasDirty = false
            @textDirty = false
            @controlPointObjs = null
            @textXOffset = 0
            @textYOffset = null
            @fadeOutDelay = options.fadeOutDelay or 250
            @letterMetrics = options.letterMetrics or @parentView?.letterMetrics or new LetterMetrics()
            @colorPalette = options.colorPalette or @parentView?.colorPalette
            @letterFill = options.letterFill  # overrides letter colors
            @useLetterAreas = true
            @isOutOfBounds = false
            @listenTo(@, 'change:isOutOfBounds', @onIsOutOfBoundsChange)
            @listenTo(@letterMetrics, 'cache:invalidate', @onMetricsCacheInvalidate)

            if $.browser.webkit
                @tryForceRepaint = @forceRepaint
            else
                @tryForceRepaint = ->

        onModelBind: ->
            super
            @listenTo(@model, 'clear', @onClear)
            @listenTo(@model, 'change:path', @invalidateBoundaryInfo)
            @listenTo(@model, 'change:fontSize', @invalidateBoundaryInfo)
            @listenTo(@model, 'change:transformMatrix', @invalidateBoundaryInfo)

        onParentViewBind: ->
            super
            @listenTo(@parentView, 'change:pageContainerScale', @onCanvasScaleChange)
            @listenTo(@parentView.dataModel, 'change:textDirection', @onTextDirectionChange)

        onParentViewUnbind: ->
            @stopListening(@parentView.model)
            @stopListening(@parentView.dataModel)
            super

        remove: =>
            @stopListening(@letterMetrics)
            @stopListening(this)
            @stopListening(@model)
            @stopListening(@colorPalette)
            fadeOutDelay = if @fadeoutOnRemove then @fadeOutDelay else 0
            helper = =>
                @removeTextPath()
                @_clipRect?.remove()
                delete @colorPalette
                delete @paper
            if fadeOutDelay > 0
                @fadeOut(fadeOutDelay)
                _.delay((=>
                    helper()
                    super
                ), fadeOutDelay)
            else
                helper()
                super

        ###
        event handlers
        ###

        onClear: ->
            @textDirty = true

        onTextDirectionChange: ->
            # re-creating the text path - we may use other engine
            @reCreateTextPath()

        onMetricsCacheInvalidate: ->
            @reCreateTextPath()

        ###
        useful getters
        ###

        getStartPoint: -> @model.get('startPoint')

        getEndPoint: -> @model.get('endPoint')

        getControlPoints: -> @model.get('controlPoints')

        getPath: -> @model.path

        getPoints: -> @model.getPoints()

        getText: -> @model.get('text')

        getLetters: -> @model.get('text').split('')

        getNextLetter: -> @model.get('nextLetter') or null

        getPreviousLetter: -> @model.get('previousLetter') or null

        getFontSize: -> Math.round(@model.get('fontSize'))

        getTransformMatrix: -> @model.get('transformMatrix')

        getCanvasScale: -> @parentView?.getCanvasScale() or 1.0

        getTextDirection: -> @parentView?.getTextDirection?() or 'ltr'

        isTextRTL: -> @getTextDirection() == 'rtl'

        # these are overriden in languagegarden.editor.views.elements
        isDebugMode: -> false

        isDraggedNow: -> false

        isEditedNow: -> false

        # coordinate convertions path <-> screen
        # required when any transforms are applied

        pathToScreenCoordinates: (x, y) ->
            Point.applyMatrixToXY(x, y, @model.get('transformMatrix'))

        screenToPathCoordinates: (x, y) ->
            # use dragging method cache if possible
            # TODO: perhaps the inverted matrix should be stored in the model
            # aside the regular one
            if @_drag?.initialMatrixInv?
                matrix = @_drag.initialMatrixInv
            else
                matrix = @model.get('transformMatrix').invert()
            Point.applyMatrixToXY(x, y, matrix)

        getLetterStyleAttrs: (letterIndex) ->
            fill = []

            # produce list of colors
            for l in @model.getLetterAttribute(letterIndex, 'labels') or []
                if _.isString(l)
                    fill.push([
                        @letterFill or @colorPalette?.getColorForLabel(l) or
                        @colorPalette?.get('newWordColor')
                    , 1])
                else
                    # assuming that l is a dict
                    fill.push([
                        @letterFill or
                        l.color or
                        @colorPalette?.getColorForLabel(l.name) or
                        @colorPalette?.get('newWordColor')
                    , if l.size? then l.size else 1])


            # in case there is no color label yet
            if fill.length == 0
                fill = [[@letterFill or @colorPalette?.get('newWordColor'), 1]]

            {'fill': fill}

        getLettersStyleAttrs: ->
            (@getLetterStyleAttrs(i) for i in [0...@getLetters().length])

        getGenericLettersLengths: (letters, fontSize) ->
            fontSize ?= @getFontSize()
            opts = {}
            lengths = []
            lettersLen = letters.length
            for i in [0...lettersLen]
                if i == 0
                    opts.previousLetter = @getPreviousLetter()
                else
                    opts.previousLetter = letters[i - 1]
                if i == lettersLen - 1
                    opts.nextLetter = @getNextLetter()
                else
                    opts.nextLetter = letters[i + 1]

                opts.boundary = i in [0, lettersLen - 1]

                ml = @getMetricsLetter(letters[i], opts)
                lengths.push(@letterMetrics.getLength(ml, fontSize))
            lengths

        getLettersLengths: -> @getGenericLettersLengths(@getLetters())

        getGenericTextLettersLength: (letters, fontSize) ->
            sum(@getGenericLettersLengths(letters, fontSize))

        getSpaceLength: -> @textPath?.getSpaceLength() or 0

        getMetricsLetter: (letter, options) ->
            options ?= {}
            options.isTextRTL = @isTextRTL()
            wrapLetterWithZWJ(letter, options)

        getMaxLetterHeight: ->
            @getFontSize() * settings.fontSizeToLetterHeightMultiplier

        getLetterStartPathPositions: ->
            @textPath?.getLetterStartPathPositions() or []

        getLetterPathPosition: (letterIndex, letterLengthFactor) ->
            @textPath?.getLetterPathPosition(letterIndex, letterLengthFactor) or 0

        getLetterStartPathPosition: (letterIndex) ->
            @getLetterPathPosition(letterIndex, 0.0)

        getLetterMiddlePathPosition: (letterIndex) ->
            @getLetterPathPosition(letterIndex, 0.5)

        getLetterEndPathPosition: (letterIndex) ->
            @getLetterPathPosition(letterIndex, 1)

        invalidateBoundaryInfo: ->
            @_bbox = null
            @_letterAreaInfos = null

        _getBBox: ->
            text = @getText()
            if text.length > 0
                path = @getPath()
                deviation = @getMaxLetterHeight() / 2
                firstLength = @getLetterMiddlePathPosition(0)
                lastLength = @getLetterMiddlePathPosition(text.length - 1)
                firstOrtho = path.getOrthogonalAtLength(firstLength)
                .normalize()
                .mulSelf(deviation)
                lastOrtho = path.getOrthogonalAtLength(lastLength)
                .normalize()
                .mulSelf(deviation)
                upperPath = getBigUpperPath(path, firstOrtho, lastOrtho)
                lowerPath = getBigLowerPath(path, firstOrtho, lastOrtho)
                ex1 = upperPath.getExtremaPoints()
                ex2 = lowerPath.getExtremaPoints()
                points = [
                    upperPath.getStartPoint(), upperPath.getEndPoint(),
                    lowerPath.getStartPoint(), lowerPath.getEndPoint(),
                ].concat(ex1, ex2)

                mat = @model.get('transformMatrix')
                matTransformApp = Point.getTransformApplicator(mat)

                BBox.fromPointList(points).applyToPoints(matTransformApp)
            else
                BBox.newEmpty()

        getBBox: ->
            if not @_bbox?
                @_bbox = @_getBBox()
            @_bbox

        getIntersectionInfo: (bbox) ->
            info =
                view: this
                letterObject: null
                letterIndex: null
                isBoundary: null
                intersects: false
            if @getBBox().intersects(bbox)
                # the global box intersects, now check if any of the bboxes of
                # letters also intersect.
                # assert @textPath?
                letters = @getLetters()
                for i in [0...letters.length]
                    letterObj = @textPath.getLetterObj(i)
                    r = letterObj.node.getClientRects()[0]
                    if not r?
                        continue
                    if r.width == 0 and r.height == 0
                        # IE10 detected... we can't use getClientRects() on
                        # letter tspan nodes to measure the bbox, we can't
                        # also use the getBBox() method, therefore we base
                        # the intersection on the whole text element (which
                        # we already checked)
                        # TODO: use calculations similar to used by the
                        # letter areas
                        info.intersects = true
                        info.letterObject = letterObj
                        info.letterIndex = i
                        info.isBoundary = (i in [0, letters.length - 1])
                        break
                    # transforming the client rect to canvas coordinates
                    [rl, rt] = @parentView.transformToCanvasCoords(r.left,
                                                                   r.top)
                    [rw, rh] = @parentView.transformToCanvasCoordOffsets(r.width,
                                                                         r.height)
                    letterBBox = BBox.fromXYWH(rl, rt, rw, rh)
                    if letterBBox.intersects(bbox)
                        info.intersects = true
                        info.letterObject = letterObj
                        info.letterIndex = i
                        info.isBoundary = (i in [0, letters.length - 1])
                        break
            info

        intersects: (bbox) -> @getIntersectionInfo(bbox).intersects

        calculateNormal: (p1, p2) ->
            Point.getNormal(p1, p2)

        ###
        helpers
        ###

        applyTransformMatrix: (matrix) ->
            @textPath?.applyTransformMatrix(matrix)

        disableSelection: ->
            @textPath?.disableSelection()

        # for textPath
        putElementToFrontAtLayer: (svgElem, layerType) ->
            @parentView.putElementToFrontAtLayer(svgElem, layerType)

        putTextPathToFront: ->
            @textPath?.toFront()

        putLetterAreaToFront: (letterArea) ->
            if not letterArea?
                return
            @parentView.putElementToFrontAtLayer(letterArea,
                                                 CanvasLayers.LETTER_AREAS)

        toFront: ->
            if not @parentView
                return
            @putTextPathToFront()
            if @letterAreas?
                for la in @letterAreas
                    @putLetterAreaToFront(la)

        ###
        letter areas helpers
        ###

        _getLetterAreaInfos: ->
            letters = @getLetters()
            if letters.length == 0
                return []
            [pathStart, pathControls..., pathEnd] = @getPoints()
            fontSize = @getFontSize()
            mat = @model.get('transformMatrix')
            path = @getPath()

            deviation = @getMaxLetterHeight() / 2

            lengths = @getLettersLengths()
            startPathPositions = @getLetterStartPathPositions()
            pairs = _.zip(startPathPositions, lengths)
            middlePathPositions = (p[0] + p[1] * 0.5 for p in pairs)
            endPathPositions = (p[0] + p[1] for p in pairs)

            ptTfApplicator = Point.getTransformApplicator(mat)
            vecTfApplicator = Point.getVectorTransformApplicator(mat)
            orthoApplicator = (p) ->
                vecTfApplicator(p.normalize().mulSelf(deviation))

            startPoints = path.getPointsAtLengths(startPathPositions)
            endPoints = path.getPointsAtLengths(endPathPositions)
            # applying transformations
            for p in startPoints
                ptTfApplicator(p)
            for p in endPoints
                ptTfApplicator(p)

            orthogonals = path.getOrthogonalsAtLengths(middlePathPositions)
            # applying transformations + normalization
            for v in orthogonals
                orthoApplicator(v)

            _.map(
                _.zip(letters, startPoints, endPoints, orthogonals),
                (args) -> getLetterAreaPathStringAndPoints(args...)
            )

        getLetterAreaInfos: ->
            if not @_letterAreaInfos?
                @_letterAreaInfos = @_getLetterAreaInfos()
            @_letterAreaInfos

        createLetterAreas: ->
            @updateLetterAreas()

        removeLetterAreas: ->
            if not @letterAreas? then return
            area.remove() for area in @letterAreas
            @letterAreas = null

        updateLetterAreas: ->
            # we do not update when dragging or editing because it
            # is very costly.
            if not @useLetterAreas or @isDraggedNow() or @isEditedNow()
                @letterAreasDirty = true
                return

            transparentColor = 'rgba(0,0,0,0)'
            blackColor = '#000000'
            showBorders = @isDebugMode()
            if not @letterAreas?
                @letterAreas = []
            laInfos = @getLetterAreaInfos(true)
            if laInfos.length < @letterAreas.length
                tail = @letterAreas[laInfos.length..]
                areasToUpdate = @letterAreas[0...laInfos.length]
                @letterAreas = areasToUpdate
                for la in tail
                    @unbindLetterArea(la)
                    la.remove()
            else
                laInfosCreating = laInfos[@letterAreas.length..]
                areasToUpdate = @letterAreas[..]
                if showBorders
                    borderWidth = 1
                    borderColor = blackColor
                else
                    borderWidth = 0
                    borderColor = transparentColor
                for laInfo in laInfosCreating
                    la = @paper.path(laInfo.pathString)
                    disableSelection(la.node)
                    # this fill is needed, because the path is hollow by
                    # default
                    la.attr
                        'fill': transparentColor
                        'stroke-width': borderWidth
                        'stroke': borderColor
                    addSVGElementClass(la.node, 'letter-area')
                    la.node.setAttribute('data-object-id',
                                         @model.get('objectId'))
                    la.node.setAttribute('data-letter-index',
                                         @letterAreas.length)
                    @bindLetterArea(la, @letterAreas.length)
                    @putLetterAreaToFront(la)
                    @letterAreas.push(la)

            counter = 0
            for la in areasToUpdate
                laInfo = laInfos[counter]
                la.attr
                    path: laInfo.pathString
                counter += 1

        ###Letter area based comparisons.###
        isInsideCanvas: -> @isInsideBBox(@parentView.getCanvasBBox(true))

        isInsideBBox: (containerBBox) ->
            if containerBBox.containsBBox(@getBBox())
                return true

            _.all @getLetterAreaInfos(), (laInfo) ->
                containerBBox.containsPoints(laInfo.pathPoints)

        getLetterAreaPoints: ->
            _.flatten(_.pluck(@getLetterAreaInfos(), 'pathPoints'))

        setIsOutOfBounds: (value) ->
            if @isOutOfBounds != value
                @isOutOfBounds = value
                @trigger('change:isOutOfBounds', @)

        onIsOutOfBoundsChange: ->
            @textPath.toggleCSSClass('out-of-bounds', @isOutOfBounds, true)
            @updateTextPath()

        getTextPathClass: ->
            # RTL causes a lot of problems when using SVG textpath on different
            # browsers. Also Firefox above version 26 has trouble with the
            # SVG textpaths, see:
            #
            # https://bugzilla.mozilla.org/show_bug.cgi?id=987077
            #
            # (the bug is marked as fixed, but it is only fixed for specific case)
            if @isTextRTL() or ($.browser.mozilla and $.browser.versionNumber > 26)
                SyntheticTextPath
            else
                TextPath

        ###
        text path creation/replacement/update/deletion
        ###
        createTextPath: ->
            # assert not @tpObj?
            cls = @getTextPathClass()
            @textPath = new cls(@getTextPathOptions())
            @textPath.create()

            @textPath.addCSSClass('element')
            @createLetterAreas()
            @toFront()
            @disableSelection()

            debugMode = @isDebugMode()

            if debugMode and settings.debug.showCircles
                @reCreateControlPoints()

        getTextPathOptions: ->
            paper: @paper
            parentView: this
            objectId: @model.get('objectId')
            fontSize: @getFontSize()
            path: @getPath()
            letters: @getLetters()
            previousLetter: @getPreviousLetter()
            nextLetter: @getNextLetter()
            lettersLengths: @getLettersLengths()
            lettersStyleAttrs: @getLettersStyleAttrs()

        removeTextPath: ->
            @textPath?.remove()
            @removeControlPoints()
            @removeLetterAreas()

        setTextPathProps: ->
            @textPath.setFontSize(@getFontSize())
            @textPath.setPath(@getPath())
            @textPath.setLetters(@getLetters())
            @textPath.setNextLetter(@getNextLetter())
            @textPath.setPreviousLetter(@getPreviousLetter())
            @textPath.setLettersStyleAttrs(@getLettersStyleAttrs())
            @textPath.setLettersLengths(@getLettersLengths())
            @textPath.setTransformMatrix(@getTransformMatrix())

        updateTextPath: ->
            @setTextPathProps()
            @textPath.update()
            @updateLetterAreas()
            @updateControlPoints()

        reCreateTextPath: ->
            @removeTextPath()
            @createTextPath()

        ###
        event binding
        ###

        getLetterEventDispatcher: (eventName, isBoundary) =>
            boundaryPrefix = if isBoundary then 'bound' else 'middle'
            fullEventName = "#{boundaryPrefix}letter#{eventName}"
            (args...) =>
                selPrefix = if @selected then 'selected' else ''
                handler = @parentView.getModeBehaviorHandler("#{selPrefix}#{fullEventName}")
                if handler?
                    handler(this, args...)
                    true
                else
                    false

        letterAreaEventsHammer: (area, click, dblclick, drag, dragstart, dragend) =>

            hammerDrag = (e) ->
                drag(e, e.deltaX, e.deltaY, e.center.x, e.center.y)
            hammerDragstart = (e) =>
                dragstart(e, e.center.x, e.center.y)
            hammer = Hammer(area.node)
            pan = new Hammer.Pan(threshold: 10)
            hammer.add(pan)
            hammer
                .on('tap', click)
                .on('doubletap', dblclick)
                .on('pan', hammerDrag)
                .on('panstart', hammerDragstart)
                .on('panend', dragend)

        bindLetterArea: (letterArea, letterIndex) ->
            isBoundary = letterIndex in [0, @getText().length - 1]
            clickDispatcher = @getLetterEventDispatcher('click', isBoundary)
            dblClickDispatcher = @getLetterEventDispatcher(
                'dblclick', isBoundary)
            dragDispatcher = @getLetterEventDispatcher('drag', isBoundary)
            dragStartDispatcher = @getLetterEventDispatcher(
                'dragstart', isBoundary)
            dragEndDispatcher = @getLetterEventDispatcher('dragend', isBoundary)

            click = (e) => clickDispatcher(e, letterIndex: letterIndex)

            dblclick = (e) => dblClickDispatcher(e, letterIndex: letterIndex)

            drag = (e, dx, dy, x, y) =>
                [x, y] = @parentView.transformToCanvasCoords(x, y)
                [dx, dy] = @parentView.transformToCanvasCoordOffsets(dx, dy)
                dragDispatcher(e, x, y, dx, dy, letterIndex: letterIndex)

            dragstart = (e, x, y) =>
                [x, y] = @parentView.transformToCanvasCoords(x, y)
                dragStartDispatcher(e, x, y, letterIndex: letterIndex)

            dragend = (e) => dragEndDispatcher(e, letterIndex: letterIndex)

            @letterAreaEventsHammer(
                letterArea, click, dblclick, drag, dragstart, dragend
            )

        unbindLetterArea: (letterArea) ->
            #TODO: unbind

        ###
        rendering
        ###

        render: =>
            text = @getText() or ''
            if @textPath?
                if text.length > 0
                    @updateTextPath()
                else
                    @removeTextPath()
            else if text.length > 0
                @createTextPath()

        ###
        control point creation/replacement/update/deletion
        ###

        createControlPoints: ->
            # assert not @controlPointObjs?
            @controlPointObjs = []
            for p in @getPoints()
                @controlPointObjs.push(@paper.circle(p.x, p.y, 10))

        updateControlPoints: ->
            # assert @getPoints().length == @controlPointObjs
            if @controlPointObjs?
                points = @getPoints()
                for i in [0...points.length]
                    p = points[i]
                    @controlPointObjs[i].attr
                        cx: p.x
                        cy: p.y

        removeControlPoints: ->
            if @controlPointObjs?
                cpObj.remove() for cpObj in @controlPointObjs
                @controlPointObjs = null

        reCreateControlPoints: ->
            @removeControlPoints()
            @createControlPoints()

        ###Draws an invisible rectangle at the bounding box, of size
        original * (1 + 2 * margin).

        Drawing hidden rectangle or showing it for short period of time won't
        do the trick.
        Another working option would be to use a clipPath which will work even
        if added to defs (thus not actually visible) and does not need to be
        associated with the text to force the repaint, see:
        http://jsfiddle.net/8Y2kC/7/

        ###
        forceRepaint: (Xmargin=0.4, Ymargin=0.4) ->
            bbox = @getBBox()

            x = bbox.getLeft()
            y = bbox.getTop()

            width = bbox.getWidth()
            height = bbox.getHeight()
            widthMargin = width * Xmargin
            heightMargin = height * Ymargin

            @_clipRect ?= @paper.rect(0, 0, 1, 1)
                .attr(stroke: 'none')
            @_clipRect.attr
                x: x - widthMargin
                y: y - heightMargin
                width: width + widthMargin * 2
                height: height + heightMargin * 2
            @_clipRect

        fadeOut: (delay=250) =>
            @tpObj?.animate({opacity: 0}, 250)

        setCoreOpacity: (opacity) ->
            if not @textPath?
                return
            @textPath
            .setOpacity(opacity)
            .updateOpacity()

        @getAnimations: (diff, viewSelector, options={}) ->
            parentForceStep = options.forceStep
            splittedDiff = splitDiff(diff, false)
            rootAttributes = _.map(splittedDiff, (x) -> x[0])
            elementTextChanged = _.all(['text', 'endPoint', 'controlPoints'], (x) -> x in rootAttributes)
            transformRender = isSubset(rootAttributes, ['startPoint', 'endPoint', 'controlPoints', 'fontSize'])
            forceStep = elementTextChanged or parentForceStep
            opts =
                forceStep: forceStep
                callRender: false
                helpers: options.helpers

            animations = getAnimations(diff, viewSelector, opts)

            if transformRender
                renderUpdate = (t) ->
                    # we update only the path and the span, because
                    # using the render slows everything down
                    view = viewSelector()
                    view.textPath.setPath(view.getPath())
                    view.textPath.setFontSize(view.getFontSize())
                    view.textPath.setLettersLengths(view.getLettersLengths())
                    view.textPath.updateGradients()
                    view.textPath.updatePath()
                    view.textPath.updateFontSize()
                    view.textPath.updateSpan()
                    view.textPath.updateEachTime()
            else
                renderUpdate = (t) ->
                    view = viewSelector()
                    view.render()

            # we use special animation which will be run in parallel
            # and cause the element to re-render()
            anim = new Animation
                transitionsEnabled: not forceStep
                startCallback: ->
                    view = viewSelector()
                    view.render()
                    @oldUseLetterAreas = view.useLetterAreas
                    view.useLetterAreas = false
                update: renderUpdate
                endCallback: ->
                    view = viewSelector()
                    view.useLetterAreas = @oldUseLetterAreas
                    view.render()
                debugInfo:
                    info: 'render element animation'
                    diff: diff
            animations.push(anim)

            if elementTextChanged and not parentForceStep
                anim = new Animation
                    update: (t) ->
                        # when the element text changes, we discard the
                        # stretch animation and do a nice fade-in instead
                        viewSelector().setAnimOpacity(t)
                    debugInfo:
                        info: 'visibility element animation'
                        diff: diff
                animations.push(anim)

            animations


    class SettingsElementView extends ElementView

        putTextPathToFront: ->

        putLetterAreaToFront: (letterArea) ->


    module.exports =
        SettingsElementView: SettingsElementView
        ElementView: ElementView
