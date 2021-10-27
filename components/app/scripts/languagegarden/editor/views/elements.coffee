    'use strict'

    require('raphael')
    require('jquery.browser')

    Hammer                          = require('hammerjs')
    _                               = require('underscore')
    jQuery                          = require('jquery')
    $                               = require('jquery')


    {OpacityAwareView}              = require('./base')
    {SyntheticTextPath}             = require('./textpaths')
    {
        getLetterAreaPathStringAndPoints
        getBigUpperPath
        getBigLowerPath
    }                               = require('./utils/letterareas')
    {getTrimmedWordParams}          = require('./utils/elementsplit')
    {
        addSVGElementClass
        removeSVGElementClass
        setCaretPosition
        getCaretPosition
        disableSelection
    }                               = require('./utils/dom')
    {LetterMetrics}                 = require('./svg/svgmetrics')

    {Point}                         = require('./../math/points')
    {Point}                         = require('./../math/points')
    {BBox}                          = require('./../math/bboxes')

    settings                        = require('./../../settings')

    {
        VisibilityType,
        CanvasLayers
    }                               = require('./../constants')

    {
        sum
        wrapLetterWithZWJ
    }                               = require('./../utils')


    class ElementView extends OpacityAwareView

        initialize: (options) =>
            super(options)
            @paper              = options.paper or @parentView?.paper
            @textPath           = null
            @letterAreas        = []
            @textDirty          = false
            @controlPointObjs   = null
            @textXOffset        = 0
            @textYOffset        = null
            @fadeOutDelay       = options.fadeOutDelay or 250
            @letterMetrics      = options.letterMetrics or @parentView?.letterMetrics or new LetterMetrics()
            @colorPalette       = options.colorPalette or @parentView?.colorPalette
            @letterFill         = options.letterFill
            @useLetterAreas     = true
            @isOutOfBounds      = false
            @listenTo(@,                'change:isOutOfBounds',     @onIsOutOfBoundsChange)
            @listenTo(@letterMetrics,   'cache:invalidate',         @onMetricsCacheInvalidate)

        onModelBind: ->
            super
            @listenTo(@model,           'clear',                    @onClear)
            @listenTo(@model,           'change:path',              @invalidateBoundaryInfo)
            @listenTo(@model,           'change:fontSize',          @invalidateBoundaryInfo)
            @listenTo(@model,           'change:transformMatrix',   @invalidateBoundaryInfo)

        onParentViewBind: ->
            super
            @listenTo(@parentView,              'change:pageContainerScale',    @onCanvasScaleChange)
            @listenTo(@parentView.dataModel,    'change:textDirection',         @onTextDirectionChange)

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

        onClear:                    -> @textDirty = true
        onTextDirectionChange:      -> @reCreateTextPath()
        onMetricsCacheInvalidate:   -> @reCreateTextPath()
        getStartPoint:              -> @model.get('startPoint')
        getEndPoint:                -> @model.get('endPoint')
        getControlPoints:           -> @model.get('controlPoints')
        getPoints:                  -> @model.getPoints()
        getPath:                    -> @model.path
        getText:                    -> @model.get('text')
        getLetters:                 -> @model.get('text').split('')
        getNextLetter:              -> @model.get('nextLetter') or null
        getPreviousLetter:          -> @model.get('previousLetter') or null
        getFontSize:                -> Math.round(@model.get('fontSize'))
        getTransformMatrix:         -> @model.get('transformMatrix')
        getCanvasScale:             -> @parentView?.getCanvasScale() or 1.0
        getTextDirection:           -> @parentView?.getTextDirection?() or 'ltr'
        isTextRTL:                  -> @getTextDirection() == 'rtl'
        isDebugMode:                -> false
        isDraggedNow:               -> false
        isEditedNow:                -> false
        pathToScreenCoordinates: (x, y) -> Point.applyMatrixToXY(x, y, @model.get('transformMatrix'))

        screenToPathCoordinates: (x, y) ->
            if @_drag?.initialMatrixInv?
                matrix = @_drag.initialMatrixInv
            else
                matrix = @model.get('transformMatrix').invert()
            Point.applyMatrixToXY(x, y, matrix)

        getLetterStyleAttrs: (letterIndex) ->
            fill = []

            for l in @model.getLetterAttribute(letterIndex, 'labels') or []
                if _.isString(l)
                    fill.push([@letterFill or @colorPalette?.getColorForLabel(l) or @colorPalette?.get('newWordColor'), 1])
                else
                    fill.push([@letterFill or l.color or @colorPalette?.getColorForLabel(l.name) or @colorPalette?.get('newWordColor'), if l.size? then l.size else 1])

            if fill.length == 0
                fill = [[@letterFill or @colorPalette?.get('newWordColor'), 1]]

            {'fill': fill}

        getLettersStyleAttrs: -> (@getLetterStyleAttrs(i) for i in [0...@getLetters().length])

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

        getLettersLengths:          -> @getGenericLettersLengths(@getLetters())
        getGenericTextLettersLength: (letters, fontSize) -> sum(@getGenericLettersLengths(letters, fontSize))
        getSpaceLength:             -> @textPath?.getSpaceLength() or 0

        getMetricsLetter: (letter, options) ->
            options ?= {}
            options.isTextRTL = @isTextRTL()
            wrapLetterWithZWJ(letter, options)

        getMaxLetterHeight:                                         -> @getFontSize() * settings.fontSizeToLetterHeightMultiplier
        getLetterStartPathPositions:                                -> @textPath?.getLetterStartPathPositions() or []
        getLetterPathPosition: (letterIndex, letterLengthFactor)    -> @textPath?.getLetterPathPosition(letterIndex, letterLengthFactor) or 0
        getLetterStartPathPosition: (letterIndex)                   -> @getLetterPathPosition(letterIndex, 0.0)
        getLetterMiddlePathPosition: (letterIndex)                  -> @getLetterPathPosition(letterIndex, 0.5)
        getLetterEndPathPosition: (letterIndex)                     -> @getLetterPathPosition(letterIndex, 1)

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
                letters = @getLetters()
                for i in [0...letters.length]
                    letterObj = @textPath.getLetterObj(i)
                    r = letterObj.node.getClientRects()[0]
                    if not r?
                        continue
                    if r.width == 0 and r.height == 0
                        info.intersects = true
                        info.letterObject = letterObj
                        info.letterIndex = i
                        info.isBoundary = (i in [0, letters.length - 1])
                        break
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

        intersects: (bbox)                              -> @getIntersectionInfo(bbox).intersects
        applyTransformMatrix: (matrix)                  -> @textPath?.applyTransformMatrix(matrix)
        disableSelection:                               -> @textPath?.disableSelection()
        putElementToFrontAtLayer: (svgElem, layerType)  -> @parentView.putElementToFrontAtLayer(svgElem, layerType)
        putTextPathToFront:                             -> @textPath?.toFront()

        putLetterAreaToFront: (letterArea) ->
            if not letterArea?
                return
            @parentView.putElementToFrontAtLayer(letterArea, CanvasLayers.LETTER_AREAS)

        toFront: ->
            if not @parentView
                return
            @putTextPathToFront()
            if @letterAreas?
                for la in @letterAreas
                    @putLetterAreaToFront(la)

        _getLetterAreaInfos: ->
            letters = @getLetters()
            if letters.length == 0
                return []
            [pathStart, pathControls..., pathEnd] = @getPoints()
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
            for p in startPoints
                ptTfApplicator(p)
            for p in endPoints
                ptTfApplicator(p)

            orthogonals = path.getOrthogonalsAtLengths(middlePathPositions)
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

        createLetterAreas: -> @updateLetterAreas()

        removeLetterAreas: ->
            if not @letterAreas? then return
            area.remove() for area in @letterAreas
            @letterAreas = null

        updateLetterAreas: ->
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
                    la.attr
                        'fill': transparentColor
                        'stroke-width': borderWidth
                        'stroke': borderColor
                    addSVGElementClass(la.node, 'letter-area')
                    la.node.setAttribute('data-object-id', @model.get('objectId'))
                    la.node.setAttribute('data-letter-index', @letterAreas.length)
                    @bindLetterArea(la, @letterAreas.length)
                    @putLetterAreaToFront(la)
                    @letterAreas.push(la)

            counter = 0
            for la in areasToUpdate
                laInfo = laInfos[counter]
                la.attr
                    path: laInfo.pathString
                counter += 1

        isInsideCanvas: -> @isInsideBBox(@parentView.getCanvasBBox(true))

        isInsideBBox: (containerBBox) ->
            if containerBBox.containsBBox(@getBBox())
                return true

            _.all @getLetterAreaInfos(), (laInfo) ->
                containerBBox.containsPoints(laInfo.pathPoints)

        getLetterAreaPoints: -> _.flatten(_.pluck(@getLetterAreaInfos(), 'pathPoints'))

        setIsOutOfBounds: (value) ->
            if @isOutOfBounds != value
                @isOutOfBounds = value
                @trigger('change:isOutOfBounds', @)

        onIsOutOfBoundsChange: ->
            @textPath.toggleCSSClass('out-of-bounds', @isOutOfBounds, true)
            @updateTextPath()

        getTextPathClass: -> SyntheticTextPath

        createTextPath: ->
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

            hammerDrag          = (e) -> drag(e, e.deltaX, e.deltaY, e.center.x, e.center.y)
            hammerDragstart     = (e) => dragstart(e, e.center.x, e.center.y)
            hammer              = Hammer(area.node)
            pan                 = new Hammer.Pan(threshold: 10)
            hammer.add(pan)
            hammer
                .on('tap', click)
                .on('doubletap', dblclick)
                .on('pan', hammerDrag)
                .on('panstart', hammerDragstart)
                .on('panend', dragend)

        bindLetterArea: (letterArea, letterIndex) ->
            isBoundary          = letterIndex in [0, @getText().length - 1]
            clickDispatcher     = @getLetterEventDispatcher('click', isBoundary)
            dblClickDispatcher  = @getLetterEventDispatcher('dblclick', isBoundary)
            dragDispatcher      = @getLetterEventDispatcher('drag', isBoundary)
            dragStartDispatcher = @getLetterEventDispatcher('dragstart', isBoundary)
            dragEndDispatcher   = @getLetterEventDispatcher('dragend', isBoundary)

            click               = (e) => clickDispatcher(e, letterIndex: letterIndex)

            dblclick            = (e) => dblClickDispatcher(e, letterIndex: letterIndex)

            drag                = (e, dx, dy, x, y) =>

                                    [x, y] = @parentView.transformToCanvasCoords(x, y)
                                    [dx, dy] = @parentView.transformToCanvasCoordOffsets(dx, dy)
                                    dragDispatcher(e, x, y, dx, dy, letterIndex: letterIndex)

            dragstart           = (e, x, y) =>

                                    [x, y] = @parentView.transformToCanvasCoords(x, y)
                                    dragStartDispatcher(e, x, y, letterIndex: letterIndex)

            dragend             = (e) => dragEndDispatcher(e, letterIndex: letterIndex)

            @letterAreaEventsHammer(letterArea, click, dblclick, drag, dragstart, dragend)

        unbindLetterArea: (letterArea) -> #TODO: unbind

        render: =>
            text = @getText() or ''
            if @textPath?
                if text.length > 0
                    @updateTextPath()
                else
                    @removeTextPath()
            else if text.length > 0
                @createTextPath()

        createControlPoints: ->
            @controlPointObjs = []
            for p in @getPoints()
                @controlPointObjs.push(@paper.circle(p.x, p.y, 10))

        updateControlPoints: ->
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

        forceRepaint: (Xmargin=0.4, Ymargin=0.4) ->
            bbox = @getBBox()

            x = bbox.getLeft()
            y = bbox.getTop()

            width = bbox.getWidth()
            height = bbox.getHeight()
            widthMargin = width * Xmargin
            heightMargin = height * Ymargin

            @_clipRect ?= @paper.rect(0, 0, 1, 1).attr(stroke: 'none')
            @_clipRect.attr
                x: x - widthMargin
                y: y - heightMargin
                width: width + widthMargin * 2
                height: height + heightMargin * 2
            @_clipRect

        fadeOut: (delay=250) => @tpObj?.animate({opacity: 0}, 250)

        setCoreOpacity: (opacity) ->
            if not @textPath?
                return
            @textPath
                .setOpacity(opacity)
                .updateOpacity()


    class BaseEditorElementView extends ElementView

        initialize: (options) ->
            parentView = options.parentView or options.editor
            options.parentView = options.editor = parentView
            super(options)

        isDebugMode:    -> @parentView.debug
        isDraggedNow:   -> @parentView.dragging
        isEditedNow:    -> @parentView.mode == CanvasLayers.EDIT

        addLetterAreasClass: (cssClass) ->
            if not @letterAreas?
                # this.letterAreas may not be always initialized
                # (e.g. in edit mode)
                return
            for letterArea in @letterAreas
                addSVGElementClass(letterArea.node, cssClass)

        removeLetterAreasClass: (cssClass) ->
            if not @letterAreas?
                # this.letterAreas may not be always initialized
                # (e.g. in edit mode)
                return
            for letterArea in @letterAreas
                removeSVGElementClass(letterArea.node, cssClass)

        addCSSClass: (cssClass) ->
            if @textPath?
                @textPath.addCSSClass(cssClass)
                @addLetterAreasClass(cssClass)

        removeCSSClass: (cssClass) ->
            if @textPath?
                @textPath.removeCSSClass(cssClass)
                @removeLetterAreasClass(cssClass)

        updateVisibility: ->
            if not @textPath?
                return
            marked = @model.get('marked')
            if marked in [false, true]
                className = if marked then 'marked' else VisibilityType.FADED
            else
                className = @model.get('visibilityType') or VisibilityType.DEFAULT

            # reset old CSS classes
            for own key, value of VisibilityType
                @removeCSSClass(value)
            @removeCSSClass('marked')

            @addCSSClass(className)

        getRotationAngle: (x, y) => Raphael.angle(x, y, @_drag.startPt.toArray()..., @_drag.originPt.toArray()...)

        rotate: (x, y, angle) =>
            angle ?= @getRotationAngle(x, y)
            points = (p.copy() for p in @getPoints())

            for [pt, [x, y]] in _.zip(points, @_drag.initialPoints)
                pt.setCoords(x, y)

            angle = 0 if @_drag?.rotateZero

            Point.rotatePoints(angle, @_drag.originPt.toArray()..., points)
            @model.set('points', points)

        forceRepaint: =>
            clipRect = super(arguments...)
            @parentView.putElementToFrontAtLayer(clipRect, CanvasLayers.LETTERS)

        isSelected: => @selected

        render: ->
            super
            @updateVisibility()
            this


    class EditorElementView extends BaseEditorElementView

        initialize: (options) =>
            super(options)
            @selected = false
            @dragged = false
            @listenTo(@model,               'change:letter:style',      @render)
            @listenTo(@model,               'change:text',              => @textDirty = true)
            @listenTo(@model,               'view:select',              @select)
            @listenTo(@model,               'change:visibilityType',    @updateVisibility)
            @listenTo(@model,               'change:marked',            @updateVisibility)
            @listenTo(@parentView,          'selectchange',             @onSelectChange)
            @listenTo(@colorPalette.tools,  'all',                      @onPaletteEdited)

        remove: ->
            @stopListening(@colorPalette.tools)
            delete @colorPalette
            super

        onSelectChange:     -> @forceRepaint() if not @isSelected()
        onPaletteEdited:    -> @updateTextPath()

        addLetterAreasClass: (cssClass) =>
            for letterArea in @letterAreas
                addSVGElementClass(letterArea.node, cssClass)

        removeLetterAreasClass: (cssClass) =>
            for letterArea in @letterAreas
                removeSVGElementClass(letterArea.node, cssClass)

        changeSelection: (selected, options, property, cssClass, eventName) =>
            if @[property] == selected
                return
            @[property] = selected
            if selected
                @addCSSClass(cssClass)
            else
                @removeCSSClass(cssClass)
            if options?.silent
                return
            @trigger(eventName, this)

        setVisibilityType: (value=VisibilityType.VISIBLE, options) => @model.set('visibilityType', value, options)

        select: (selected=true, options) => @changeSelection(selected, options, 'selected', 'selected', 'selectchange')


    class EditedElementView extends BaseEditorElementView

        initialize: (options) =>
            super(options)
            @selected = true
            @initialData = {}
            for name in ['startPoint', 'controlPoints', 'endPoint', 'text', 'fontSize']
                @initialData[name] = @model.get(name)
            @listenTo(@model, 'change:text', @onModelTextChange)
            @listenTo(@model, 'change:endPoint', @onModelPointsChange)
            @initializeInput()

        initializeInput: =>
            transform = Point.getTransform(@model.get('transformMatrix'))
            inputPoint = transform(@model.get('startPoint'))

            $input = $('<input type="text">')
            $input
            .addClass('language-plant-editbox')
            .toggleClass('language-plant-editbox__rtl', @isTextRTL())
            .on
                change: @onInputChange
                keypress: @onInputKeyPress
                keyup: @onInputKeyUp
                blur: @onInputBlur
                click: @onInputClick
                dblclick: @onInputDblClick
            .attr
                autocomplete: 'off'
                spellcheck: 'false'
                autocorrect: 'off'
            .css
                'left': "#{inputPoint.x}px"
                'top': "#{inputPoint.y}px"
            .appendTo(@parentView.getChildrenContainerElement())
            .val(@model.get('text'))

            @inputEl = $input.get(0)
            @setCaretAtEnd()
            # use timeout to override "select all" caused by double click
            setTimeout(@setCaretAtEnd, 0)

        setCaretAtEnd: =>
            setCaretPosition(@inputEl, @model.get('text').length)
            if @textPath?
                @updateCaret()

        remove: =>
            $(@inputEl).remove()
            @caretObj?.remove()
            super

        render: =>
            super()
            @updateCaret()
            this

        createTextPath: =>
            super()
            # for some reason jQuery .addClass does not work, so using
            # native DOM methods
            @textPath.addCSSClass('edited')

        canSplitWord: =>
            @lastCaretPos ?= getCaretPosition(@inputEl)
            # forbidding splitting of all-space words
            if @model.get('text').trim().length == 0
                return false
            # note: zero is before the first letter, length is after last letter
            0 < @lastCaretPos < @model.get('text').length

        updateCaret: =>
            caretPos = getCaretPosition(@inputEl)
            text = @getText()
            path = @getPath()

            if text.length > 0
                if caretPos > 0
                    letterPos = caretPos - 1
                    if @isTextRTL()
                        caretPathPos = @getLetterStartPathPosition(letterPos)
                        caretVectorPathPos = @getLetterMiddlePathPosition(letterPos)
                    else
                        caretPathPos = @getLetterEndPathPosition(letterPos)
                        caretVectorPathPos = @getLetterMiddlePathPosition(letterPos)
                else
                    if @isTextRTL()
                        caretPathPos = path.getLength()
                        caretVectorPathPos = @getLetterMiddlePathPosition(0)
                    else
                        caretPathPos = 0
                        caretVectorPathPos = @getLetterMiddlePathPosition(0)

                caretCenterPoint = path.getPointAtLength(caretPathPos)
                normal = path.getOrthogonalAtLength(caretVectorPathPos).normalize()
            else
                caretCenterPoint = @getStartPoint()
                normal = new Point(0, -1)

            fontSize = @model.get('fontSize')
            height = @getMaxLetterHeight() or fontSize

            s = caretCenterPoint.add(normal.mul(height / 2))
            e = caretCenterPoint.add(normal.mul(-height / 2))

            s.setCoords(@pathToScreenCoordinates(s.toArray()...)...)
            e.setCoords(@pathToScreenCoordinates(e.toArray()...)...)

            caretColor = @parentView.getCaretColor()
            caretThickness = 3
            pathString = "M#{s.x} #{s.y}L#{e.x} #{e.y}"
            if @caretObj?
                @caretObj.attr
                    'path': pathString
                    'stroke': caretColor
            else
                @caretObj = @paper.path(pathString);
                @caretObj.attr
                    'stroke': caretColor
                    'stroke-width': caretThickness

            @parentView.selectionBBoxChange()

        updateModelTextFromInput: =>
            oldText = @model.get('text')
            oldCaretPos = if @lastCaretPos? then @lastCaretPos else oldText.length
            newCaretPos = getCaretPosition(@inputEl)
            newText = $(@inputEl).val()
            @textDirty = newText != oldText
            options =
                caretPositions:
                    current: newCaretPos
                    previous: oldCaretPos
                defaultColor: @parentView.colorPalette.get('newWordColor')

            @lastCaretPos = newCaretPos
            if @textDirty
                if oldCaretPos == oldText.length
                    @model.unset('nextLetter', silent: true)
                if oldCaretPos == 0
                    @model.unset('previousLetter', silent: true)
            @model.set('text', newText, options)
            @checkOutOfBounds()

        checkOutOfBounds: =>
            @setIsOutOfBounds(not @isInsideCanvas())

        getInitialSpaceLength: =>
            text = @initialData.text
            if text.length == 0 then 1
            else
                if not @initialData._spaceLength?
                    fontSize = @initialData.fontSize
                    textLen = @getGenericTextLettersLength(text.split(''), fontSize)
                    numOfLetters = text.length
                    numOfSpaces = if numOfLetters > 0 then numOfLetters - 1 else 0
                    pathLen = @getPath().getLength()
                    if numOfSpaces == 0
                        spaceLen = 0
                    else
                        spaceLen = (pathLen - textLen) / numOfSpaces
                    @initialData._spaceLength = spaceLen
                @initialData._spaceLength

        predictFullPathLength: (modelAttributes) =>
            spaceLen = @getInitialSpaceLength()
            text = modelAttributes.text
            fontSize = modelAttributes.fontSize
            numOfLetters = text.length
            numOfSpaces = if numOfLetters > 0 then numOfLetters - 1 else 0
            textLen = @getGenericTextLettersLength(text.split(''), fontSize)
            textLen + numOfSpaces * spaceLen

        recalculatePoints: =>
            leftToRight = true # TODO: from settings
            startPoint = @model.get('startPoint')
            text = @model.get('text')
            newPathLen = @predictFullPathLength(@model.attributes)
            if @initialData.text.length == 0
                endPoint = startPoint.copy()
                if leftToRight
                    endPoint.x += newPathLen
                else
                    endPoint.x -= newPathLen
                controlPoint = Point.avg(startPoint, endPoint)
            else
                oldPathLen = @predictFullPathLength(@initialData)
                factor = newPathLen / oldPathLen
                rescalePoint = (p) =>
                    startPoint.add(p.sub(startPoint).mul(factor))
                endPoint = rescalePoint(@initialData.endPoint)
                if text.length <= 2
                    # for short words, the text should not be bent
                    controlPoint = Point.avg(startPoint, endPoint)
                else
                    controlPoint = rescalePoint(@initialData.controlPoints[0])

            @model.set
                endPoint: endPoint
                controlPoints: [controlPoint]

        onInputChange: => @updateModelTextFromInput()

        onInputKeyPress: (event) =>
            code = if event.keyCode then event.keyCode else event.which
            if code == 13
                @updateModelTextFromInput()
                @finishEditing()
            else
                @updateModelTextFromInput()
                @updateCaret()

        onInputKeyUp: () =>
            @updateModelTextFromInput()
            @updateCaret()

        onInputBlur: () =>
            @finishEditing(blur: true)

        finishEditing: (options) =>
            @resetToInitialState() if @isOutOfBounds
            @trimContent()
            @parentView.finishEditing(options)

        resetToInitialState: (silent=true) =>
            @lastCaretPos = (@initialData.text or '').length
            @model.set(
                if @initialData.text then @initialData else {text: ''},
                # we are leaving edit anyway and this view will be disposed of
                silent: silent
            )

        shouldTrim: =>
            @model.get('text').trim().length != @model.get('text').length

        trimContent: =>
            if @model.get('text').trim().length == 0
                @model.set('text', '', silent: true)
                return

            if @shouldTrim()
                {letters, path} = getTrimmedWordParams(@)[0]
                [startli, endli] = letters
                [startPoint, controlPoints..., endPoint] = path

                # important: update lastCaretPos after removing leading spaces
                # so split will get correct parameters
                @lastCaretPos -= startli

                # update the model
                @model.set(
                    'text', @model.get('text')[startli..endli],
                    silent: true
                )
                @model.set(
                    'lettersAttributes',
                    @model.get('lettersAttributes')[startli..endli],
                    silent: true
                )
                @model.set('startPoint', startPoint, silent: true)
                @model.set('endPoint', endPoint, silent: true)
                @model.set('controlPoints', controlPoints, silent: true)

        onInputClick: (event) =>
            event.preventDefault()
            event.stopImmediatePropagation()

        onInputDblClick: (event) =>
            event.preventDefault()
            event.stopImmediatePropagation()

        onModelTextChange: => @recalculatePoints()

        onModelPointsChange: => @render()


    module.exports =
        EditorElementView:  EditorElementView
        EditedElementView:  EditedElementView
