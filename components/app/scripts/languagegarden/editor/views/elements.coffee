    'use strict'

    require('raphael')
    _ = require('underscore')
    jQuery = require('jquery')
    $ = require('jquery')
    settings = require('./../../settings')
    {VisibilityType, CanvasLayers} = require('./../constants')
    {EditorMode} = require('./../constants')
    {Point} = require('./../../math/points')
    {
        addSVGElementClass
        removeSVGElementClass
        setCaretPosition
        getCaretPosition
    } = require('./../../common/domutils')
    {ElementView} = require('./../../common/views/elements')
    {getTrimmedWordParams} = require('./../../common/views/elementsplit')



    class BaseEditorElementView extends ElementView

        initialize: (options) ->
            # TODO: refactor the editor/parentView
            parentView = options.parentView or options.editor
            options.parentView = options.editor = parentView
            super(options)

        isDebugMode: -> @parentView.debug

        isDraggedNow: -> @parentView.dragging

        isEditedNow: -> @parentView.mode == EditorMode.EDIT

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

        ###
        Override which does not use setCoreOpacity, instead uses css classes
        (we assume that we do not use setAnimOpacity in editor).
        ###
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

        ### Adds rotation to the matrix. ###
        getRotationAngle: (x, y) =>
            Raphael.angle(
                x, y, @_drag.startPt.toArray()..., @_drag.originPt.toArray()...
            )

        rotate: (x, y, angle) =>
            angle ?= @getRotationAngle(x, y)

            points = (p.copy() for p in @getPoints())

            # reset points
            for [pt, [x, y]] in _.zip(points, @_drag.initialPoints)
                pt.setCoords(x, y)

            # perform fake 0 angle roatate in one letter scale to force
            # redrawing of letter surroundings
            angle = 0 if @_drag?.rotateZero

            Point.rotatePoints(angle, @_drag.originPt.toArray()..., points)
            @model.set('points', points)

        ###Overriding super to move the repaint rect to the correct layer.###
        forceRepaint: =>
            clipRect = super(arguments...)
            @parentView.putElementToFrontAtLayer(clipRect, CanvasLayers.LETTERS)

        isSelected: => @selected

        render: ->
            super
            @updateVisibility()
            this


    class EditorElementView extends BaseEditorElementView

        # event handlers

        initialize: (options) =>
            super(options)
            @selected = false
            @dragged = false
            @listenTo(@model, 'change:letter:style', @render)
            @listenTo(@model, 'change:text', => @textDirty = true)
            @listenTo(@model, 'view:select', @select)
            @listenTo(@model, 'change:visibilityType', @updateVisibility)
            @listenTo(@model, 'change:marked', @updateVisibility)
            @listenTo(@parentView, 'selectchange', @onSelectChange)
            @listenTo(@colorPalette.tools, 'all', @onPaletteEdited)

        remove: ->
            @stopListening(@colorPalette.tools)
            delete @colorPalette
            super

        onSelectChange: ->
            # forcing repaint as some parts of the words did not apply css
            @forceRepaint() if not @isSelected()
            # TODO: after repaint, parts of letters not fitting the bounding box
            # will disappear. These are the same regions that wouldn't otherwise
            # update. The disappearance is related to opacity setting (FIXME).

        onPaletteEdited: -> @updateTextPath()

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

        setVisibilityType: (value=VisibilityType.VISIBLE, options) =>
            @model.set('visibilityType', value, options)

        select: (selected=true, options) =>
            @changeSelection(
                selected, options, 'selected', 'selected', 'selectchange'
            )


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
            # the 'hidden' input must be placed near the plant element
            # - this causes proper scroll to place with the plant element
            # in ipad safari when the virtual keyboard pops up
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
        EditorElementView: EditorElementView
        EditedElementView: EditedElementView
