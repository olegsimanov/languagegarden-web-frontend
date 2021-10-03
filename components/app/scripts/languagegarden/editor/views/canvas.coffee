    'use strict'

    Hammer = require('hammerjs')
    require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    {isDarkColor} = require('./../utils')
    {
        disableSelection
        getOffsetRect
        addSVGElementClass
    } = require('./../domutils')
    {
        ColorAction
        RemoveColorAction
        SplitColorAction
    } = require('./../actions/color')
    {EditorDummyMediumView} = require('./media/base')
    {EditorElementView, EditedElementView} = require('./elements')
    {MoveBehavior} = require('./../modebehaviors/move')
    {ColorBehavior} = require('./../modebehaviors/color')
    {StretchBehavior} = require('./../modebehaviors/stretch')
    {ScaleBehavior} = require('./../modebehaviors/scale')
    {GroupScaleBehavior} = require('./../modebehaviors/groupscale')
    {EditBehavior} = require('./../modebehaviors/edit')
    {TextEditBehavior} = require('./../modebehaviors/textedit')
    {PlantToTextBehavior} = require('./../modebehaviors/planttotext')
    {RotateBehavior} = require('./../modebehaviors/rotate')
    {EditorMode, EditorLayers, ColorMode} = require('./../constants')
    {Point} = require('./../../math/points')
    {BBox} = require('./../../math/bboxes')
    {PlantElement} = require('./../models/elements')
    {
        PlacementType
    } = require('./../constants')


    {enumerate} = require('./../utils')
    {
        disableSelection
        addSVGElementClass
    } = require('./../domutils')
    {LetterMetrics} = require('./../svgmetrics')
    {DummyMediumView} = require('./media/base')
    {ElementView} = require('./elements')
    {Point} = require('./../../math/points')
    {BBox} = require('./../../math/bboxes')
    {PlantMedium} = require('./../models/media')
    {BaseView} = require('./base')
    {
        MediumType
        PlacementType
        CanvasLayers
        CanvasMode
    } = require('./../constants')
    {Settings} = require('./../models/settings')

    class CanvasView extends BaseView
        className: 'canvas'

        initialize: (options) ->
            super
            @elementViews = {}
            @mediaViews = {}
            @colorPalette = options.colorPalette
            @setPropertyFromOptions(options, 'dataModel', required: true)
            canvasDimensions = @getCanvasSetupDimensions()
            @paper = Raphael(@$el.get(0),
                canvasDimensions[0], canvasDimensions[1])
            @updateTextDirectionFromModel()
            @$el
                .css
                    'width': canvasDimensions[0]
                    'height': canvasDimensions[1]
                .attr('unselectable', 'on')
            @$canvasEl = $(@paper.canvas)

            @settings = options.settings or Settings.getSettings(@settingsKey())

            @debug = if options?.debug? then options.debug else false

            @letterMetrics = options.letterMetrics or new LetterMetrics()

            @listenTo(@model.elements, 'add', @onElementAdd)
            @listenTo(@model.elements, 'remove', @onElementRemove)
            @listenTo(@model.elements, 'reset', @onElementsReset)

            @listenTo(@model.media, 'add', @onMediumAdd)
            @listenTo(@model.media, 'remove', @onMediumRemove)
            @listenTo(@model.media, 'reset', @onMediaReset)

            @listenTo(@model, 'change:bgColor', @onBgColorChange)
            @listenTo(@model, 'change:textDirection', @updateTextDirectionFromModel)

            @initializeModes()
            @initializeLayers()
            @initializeBackgroundObject()
            @initializeBackgroundEvents()

        onParentViewBind: ->
            eventNames = ("change:pageContainer#{suf}" for suf in ['Transform',
                'Scale', 'ShiftX', 'ShiftY'])
            @setupEventForwarding(@parentView, eventNames)

        metricKey: => "plant-#{@model.id or 'new'}"

        settingsKey: -> 'plant-view'

        initializeLayers: ->
            createLayerGuard = (name) =>
                guard = @paper.rect(0, 0, 1, 1)
                disableSelection(guard.node)
                $(guard.node).attr('id', "guard-#{name}")
                guard.hide()
                guard.toFront()
                guard
            @layerGuards = {}
            @layerGuards.images = createLayerGuard('images')
            @layerGuards.letters = createLayerGuard('letters')
            @layerGuards.letterMasks = createLayerGuard('letter-masks')

            @layerGuards.background = createLayerGuard('background')
            @layerGuards.imageAreas = createLayerGuard('image-areas')
            @layerGuards.letterAreas = createLayerGuard('letter-areas')
            @layerGuards.selectionRect = createLayerGuard('selection-rect')
            @layerGuards.selectionTooltip = createLayerGuard('selection-tooltip')
            @layerGuards.menu = createLayerGuard('menu')

        backgroundEventsHammer: (click, dblclick, drag, dragstart, dragend) ->

            hammerClick = (e) =>
                click(e, e.center.x, e.center.y)
            hammerDblClick = (e) =>
                dblclick(e, e.center.x, e.center.y)
            hammerDrag = (e) =>
                drag(e, e.deltaX, e.deltaY, e.center.x, e.center.y)
            hammerDragstart = (e) =>
                dragstart(e, e.center.x, e.center.y)
            Hammer(@backgroundObj.node)
                .on('tap', hammerClick)
                .on('doubletap', hammerDblClick)
                .on('hold', hammerDblClick)
                .on('pan', hammerDrag)
                .on('panstart', hammerDragstart)
                .on('panend', dragend)

        initializeBackgroundEvents: ->

            click = (event, x, y) =>
                [x, y] = @transformToCanvasCoords(x, y)
                @getModeBehaviorHandler('bgclick')(event, x, y)

            dblclick = (event, x, y) =>
                [x, y] = @transformToCanvasCoords(x, y)
                @getModeBehaviorHandler('bgdblclick')(event, x, y)

            drag = (e, dx, dy, x, y) =>
                [x, y] = @transformToCanvasCoords(x, y)
                [dx, dy] = @transformToCanvasCoordOffsets(dx, dy)
                @setDragging(true)
                @getModeBehaviorHandler('bgdrag')(e, x, y, dx, dy)

            dragstart = (e, x, y) =>
                [x, y] = @transformToCanvasCoords(x, y)
                @getModeBehaviorHandler('bgdragstart')(e, x, y)

            dragend = (e) =>
                @setDragging(false)
                @getModeBehaviorHandler('bgdragend')(e)

            @backgroundEventsHammer(
                click, dblclick, drag, dragstart, dragend)

            @putElementToFrontAtLayer(@backgroundObj, CanvasLayers.BACKGROUND)

        initializeBackgroundObject: =>
            @backgroundObj = @paper.rect(0, 0, 1, 1)
            disableSelection(@backgroundObj.node)
            addSVGElementClass(@backgroundObj.node, 'background-area')

            @backgroundObj
                .attr
                    width: @$canvasEl.attr("width")
                    height: @$canvasEl.attr("height")
                .toBack()
            @backgroundObj.attr
                fill: 'rgba(0,0,0,0)'
                stroke: '#000'
                'stroke-opacity': 0
                'stroke-width': 0

        initializeModes: ->
            cfg = @getModeConfig()
            @modeBehaviors = {}
            @mode = cfg.startMode
            @defaultMode = cfg.defaultMode or cfg.startMode
            for modeSpec in cfg.modeSpecs
                @addModeBehavior(modeSpec.mode, modeSpec.behaviorClass)
            cfg.initializer?.call(this)

        remove: =>
            @removeAllElementViews()
            @removeAllMediaViews()
            @backgroundObj.remove()
            @letterMetrics.remove()
            @letterMetrics = null
            @paper.clear()
            @$el.empty()
            $(window).off('load', @onLoad)
            if @model?
                @stopListening(@model.elements)
                @stopListening(@model.media)
            super

        getNoOpModeConfig: ->
            startMode: CanvasMode.NOOP
            modeSpecs: []

        getModeConfig: -> @getNoOpModeConfig()

        addModeBehavior: (mode, behaviorClass) =>
            @modeBehaviors[mode] = new behaviorClass
                controller: @controller
                parentView: this

        getModeBehaviorHandler: (eventName, mode=@mode) =>
            @modeBehaviors[mode]?.handlers[eventName]

        isModeAvailable: (mode) -> @modeBehaviors[mode]?

        getDefaultMode: -> @defaultMode

        toggleModeClass: (mode=@mode, flag=true) ->

        setMode: (mode, reload=false) =>
            if not @isModeAvailable(mode)
                return
            oldMode = @mode
            if not reload and oldMode == mode
                resetHandler = @getModeBehaviorHandler('modereset', mode)
                resetHandler(mode) if resetHandler?
                return
            leaveHandler = @getModeBehaviorHandler('modeleave', oldMode)
            enterHandler = @getModeBehaviorHandler('modeenter', mode)
            $el = $(@el)
            leaveHandler(mode) if leaveHandler?
            @toggleModeClass(@mode, false)
            @mode = mode
            @toggleModeClass(@mode, true)
            enterHandler(oldMode) if enterHandler?
            @mode = oldMode
            @setField('mode', mode)

        setDefaultMode: -> @setMode(@defaultMode)

        setNoOpMode: -> @setMode(CanvasMode.NOOP)

        updateBgColor: ->
            @$canvasEl.css('backgroundColor', @model.get('bgColor'))

        putElementToFrontAtLayer: (element, layer) ->
            layerGuard = @layerGuards[layer]
            element.insertBefore(layerGuard)

        getChildrenContainerElement: -> @$el.get(0)

        getCanvasBBox: (absolute) =>
            BBox.fromHtmlDOM(@$el, absolute)

        getCanvasSetupDimensions: ->
            [@dataModel.get('canvasWidth'), @dataModel.get('canvasHeight')]

        getCanvasScale: ->
            @parentView.getPageScale()

        transformToCanvasCoords: (x, y) ->
            @parentView.transformToCanvasCoords(x, y)

        transformToCanvasCoordOffsets: (dx, dy) ->
            @parentView.transformToCanvasCoordOffsets(dx, dy)

        transformToCanvasBBox: (bbox) ->
            @parentView.transformToCanvasBBox(bbox)

        transformCanvasToContainerCoords: (x, y) ->
            @parentView.transformCanvasToContainerCoords(x, y)

        setField: (name, value, options) =>
            oldValue = this[name]
            this[name] = value
            if oldValue != value
                @trigger("change", this)
                @trigger("change:#{name}", this, value, oldValue)

        setDebug: (debug=true) =>
            @setField('debug', debug)
            for name, view of @elementViews
                view.reCreateTextPath()
            @insertView?.reCreateTextPath()

        setDragging: (dragging) -> @setField('dragging', dragging)

        setBgDragging: (bgDragging) -> @setField('bgDragging', bgDragging)

        addPlantElement: (options) ->
            options = _.clone(options)

            if not options.fontSize?
                options.fontSize = @settings.get('fontSize')

            if not options.endPoint?
                len = @letterMetrics.getTextLength(
                    options.text, options.fontSize)
                options.endPoint = Point.fromValue(options.startPoint)
                    .add(new Point(len, 0))

            if not options.controlPoints?
                options.controlPoints = [
                    Point.getPointBetween(
                        Point.fromValue(options.startPoint),
                        Point.fromValue(options.endPoint))
                ]
            @model.addElement(options)

        addPlantElements: (texts, options) ->
            step = options.fontSize or @settings.get('fontSize')
            for [i, text] in enumerate(texts)
                opts = _.clone(options)
                opts.text = text
                opts.startPoint = [
                    opts.startPoint[0],
                    opts.startPoint[1] + i * step,
                ]
                @addPlantElement(opts)

        getElementViewConstructor: (model) ->
            (options) => new ElementView(options)

        getElementViewConstructorOptions: (model) ->
            model: model
            parentView: this
            paper: @paper

        addElementView: (model) ->
            constructor = @getElementViewConstructor(model)
            options = @getElementViewConstructorOptions(model)
            view = constructor(options)
            @elementViews["#{model.cid}"] = view
            @listenTo(view, 'selectchange', => @trigger('selectchange', view))
            view.render()

        removeElementView: (model) ->
            view = @elementViews["#{model.cid}"]
            @stopListening(view)
            view.remove()
            delete @elementViews["#{model.cid}"]

        removeAllElementViews: ->
            for cid, view of @elementViews
                @stopListening(view)
                view.remove()
            @elementViews = {}

        reloadAllElementViews: ->
            @removeAllElementViews()
            @model.elements.each (model) => @addElementView(model)

        getMediumViewClass: (model) ->
            if model.get('placementType') == PlacementType.HIDDEN
                null
            else
                null

        getMediumViewConstructor: (model) ->
            viewCls = @getMediumViewClass(model) or DummyMediumView
            (options) -> new viewCls(options)

        getMediumViewConstructorOptions: (model) ->
            model: model
            parentView: this
            paper: @paper
            containerEl: @el

        addMediumView: (model) ->
            constructor = @getMediumViewConstructor(model)
            options = @getMediumViewConstructorOptions(model)
            view = constructor(options)
            @mediaViews["#{model.cid}"] = view
            @listenTo(view, 'selectchange', => @trigger('selectchange', view))
            @listenTo(view, 'playbackchange', @onMediumViewPlaybackChange)
            view.render()

        removeMediumView: (model) ->
            view = @mediaViews["#{model.cid}"]
            @stopListening(view)
            view.remove()
            delete @mediaViews["#{model.cid}"]

        removeAllMediaViews: ->
            for cid, view of @mediaViews
                @stopListening(view)
                view.remove()
            @mediaViews = {}

        reloadAllMediaViews: ->
            @removeAllMediaViews()
            @model.media.each (model) => @addMediumView(model)

        onElementAdd: (model, collection, options) ->
            @addElementView(model)

        onElementRemove: (model, collection, options) ->
            @removeElementView(model)

        onElementsReset: (collection, options) ->
            @reloadAllElementViews()

        onMediumAdd: (model, collection, options) ->
            @addMediumView(model)

        onMediumRemove: (model, collection, options) ->
            @removeMediumView(model)

        onMediaReset: (collection, options) ->
            @reloadAllMediaViews()

        onBgColorChange: ->
            @updateBgColor()

        areViewsSynced: (viewsDict, collection) ->
            _.isEqual(_.keys(viewsDict), _.pluck(collection.models, 'cid'))

        getElementViews: => view for name, view of @elementViews

        getMediaViews: (mediaTypes) =>
            views = (view for name, view of @mediaViews)
            if mediaTypes?
                mediaTypes = [mediaTypes] if _.isString(mediaTypes)
                views = _.filter views, (v) ->
                    v?.model?.get('type') in mediaTypes
            views

        syncElementViews: ->
            if @areViewsSynced(@elementViews, @model.elements)
                for own name, view of @elementViews
                    view.render()
            else
                @reloadAllElementViews()

        syncMediaViews: ->
            if @areViewsSynced(@mediaViews, @model.media)
                for own name, view of @mediaViews
                    view.render()
            else
                @reloadAllMediaViews()

        render: =>
            @updateBgColor()
            @syncElementViews()
            @syncMediaViews()
            this

        renderView: (view, previousModelData) ->
            model = view.model
            oldType = previousModelData.type
            newType = model.get('type')
            if model instanceof PlantMedium and oldType != newType
                @removeMediumView(model)
                @addMediumView(model)
            else
                view.render()

        getTextDirection: -> @dataModel.get('textDirection') or 'ltr'

        isTextRTL: -> @getTextDirection() == 'rtl'

        updateTextDirectionFromModel: ->
            canvasEl = @paper.canvas

            if @isTextRTL()
                canvasEl.setAttribute('direction', 'rtl')
                canvasEl.setAttribute('unicode-bidi', 'bidi-override')
                canvasEl.setAttribute('writing-mode', 'rl')




    class BaseEditorCanvasView extends CanvasView
        className: "#{CanvasView::className} editor"

        initialize: (options) ->
            super
            @insertView = null

            # editor fields initial values
            @dragged = false
            @dragging = false
            @bgDragging = false

            # listening on own events
            @listenTo(this, 'selectchange', @onSelectChange)
            @listenTo(this, 'change:dragging', (s, v) => @toggleDraggingClass(v))
            @listenTo(this, 'change:bgDragging', (s, v) => @toggleBgDraggingClass(v))
            @listenTo(this, 'change:mode', @onModeChange)

            @initializeSelectionRect()
            @initializeEditorEl()

        getPlantEditorModeConfig: ->
            startMode: EditorMode.MOVE
            modeSpecs: [
                mode: EditorMode.MOVE
                behaviorClass: MoveBehavior
            ,
                mode: EditorMode.COLOR
                behaviorClass: ColorBehavior
            ,
                mode: EditorMode.STRETCH
                behaviorClass: StretchBehavior
            ,
                mode: EditorMode.SCALE
                behaviorClass: ScaleBehavior
            ,
                mode: EditorMode.GROUP_SCALE
                behaviorClass: GroupScaleBehavior
            ,
                mode: EditorMode.ROTATE
                behaviorClass: RotateBehavior
            ,
                mode: EditorMode.EDIT
                behaviorClass: EditBehavior
            ,
                mode: EditorMode.TEXT_EDIT
                behaviorClass: TextEditBehavior
            ,
                mode: EditorMode.PLANT_TO_TEXT
                behaviorClass: PlantToTextBehavior
            ]

        getModeConfig: ->
            @getPlantEditorModeConfig()


        settingsKey: -> "editor-#{super}"

        initializeSelectionRect: =>
            # initial Raphael objects
            @selectionRectObj = @paper.rect(0, 0, 1, 1)
            addSVGElementClass(@selectionRectObj.node, 'selection-area')
            disableSelection(@selectionRectObj.node)
            @selectionRectObj.hide()
            @putElementToFrontAtLayer(@selectionRectObj,
                                      EditorLayers.SELECTION_RECT)

        initializeEditorEl: =>
            @toggleModeClass()
            @toggleDraggingClass(false)
            @toggleBgDraggingClass(false)

        remove: =>
            @selectionRectObj.remove()
            @stopListening(this)
            @stopListening(@model)
            super

        ###
        Editor Fields interface
        ###

        getPaletteToolAction: (toolModel) =>
            toolModel ?= @colorPalette.get('selectedTool')
            switch toolModel.type
                when 'color' then actionCls = ColorAction
                when 'splitcolor' then actionCls = SplitColorAction
                when 'removecolor' then actionCls = RemoveColorAction

            if actionCls?
                new actionCls
                    controller: @controller
                    toolModel: toolModel

        getCaretColor: (color) =>
            color ?= @model.get('bgColor')
            if isDarkColor(color) then '#000000' else '#FFFFFF'

        toggleModeClass: (mode=@mode, flag=true) =>
            @$el.toggleClass("#{mode.replace(/\s/g,'-')}-mode", flag)

        toggleDraggingClass: (flag=true) =>
            @$el.toggleClass("in-dragging", flag)

        toggleBgDraggingClass: (flag=true) =>
            @$el.toggleClass("in-bg-dragging", flag)

        setDragging: (dragging) => @setField('dragging', dragging)

        setBgDragging: (bgDragging) => @setField('bgDragging', bgDragging)

        ###
        Adding/Removing/Resetting elements helpers
        ###

        getElementViewConstructor: (model) ->
            (options) -> new EditorElementView(options)

        getElementViewConstructorOptions: (model) ->
            model: model
            parentView: this
            editor: this
            paper: @paper

        removeElementView: (model) ->
            view = @elementViews["#{model.cid}"]
            wasSelected = view.isSelected()
            super(model)
            if wasSelected then @selectChange()

        ###
        Adding/Removing/Resetting media helpers
        ###

        getMediumViewClass: (model) ->
            if model.get('placementType') == PlacementType.HIDDEN
                null
            else
                super
        getMediumViewConstructor: (model) ->
            viewCls = @getMediumViewClass(model) or EditorDummyMediumView
            (options) -> new viewCls(options)

        getMediumViewConstructorOptions: (model) ->
            options = super
            options.editor = this
            options

        removeMediumView: (model) ->
            view = @mediaViews["#{model.cid}"]
            wasSelected = view.isSelected()
            super(model)
            if wasSelected then @selectChange()


        ###
        Event handlers
        ###

        onModeChange: =>

        restoreDefaultMode: =>
            @deselectAll()
            @setDefaultMode()

        onSelectChange: =>
            $el = $(@el)
            numOfElemSelections = @getSelectedElements().length
            selectedMediaViews = @getSelectedMediaViews()
            numOfMediaSelections = selectedMediaViews.length
            numOfSelections = @getSelectedViews().length

            useIfAvailable = (mode) =>
                if @isModeAvailable(mode)
                    return mode
                else
                    return @defaultMode

            if numOfSelections > 0
                $el.addClass('selections-present')
            else
                $el.removeClass('selections-present')

            if numOfSelections > 1
                $el.addClass('multi-select')
            else
                $el.removeClass('multi-select')

            if numOfSelections > 0
                @colorPalette.set('colorMode', ColorMode.WORD)

            if @mode == EditorMode.EDIT
                # the selection was made during edition, which means it
                # wasn't caused by user. therefore we skip the
                # mode switching part
                return

            if @mode == EditorMode.COLOR
                # we don't want to switch mode if selection was made when
                # color mode was active
                return

            # WARNING: only switch to mode behaviors which do NOT change the
            # selection when handling 'modeenter' event. In other case there
            # will be an infinite event loop
            mode = @defaultMode
            if numOfSelections == 1
                if numOfElemSelections == 1
                    if @getSelectedElements()[0].get('text').length == 1
                        # one letter word - selecting SCALE mode by default as
                        # it is the only mode available for such words
                        mode = useIfAvailable(EditorMode.SCALE)
                    else
                        mode = useIfAvailable(EditorMode.STRETCH)
                else if numOfMediaSelections == 1
                    switch selectedMediaViews[0]?.model.get('type')
                        when MediumType.IMAGE
                            mode = useIfAvailable(EditorMode.IMAGE_EDIT)
            @setMode(mode)
            @selectionBBoxChange()

        onMediumViewPlaybackChange: (player, view) =>
            if view? and view.editor == this and view.isSelected()
                @trigger('selectionplaybackchange', player, view)

        onDocumentKeyUp: (event) =>
            code = if event.keyCode then event.keyCode else event.which
            switch code
                when 17 then @multiSelect = false

        onDocumentKeyDown: (event) =>
            code = if event.keyCode then event.keyCode else event.which
            switch code
                when 17 then @multiSelect = true

        ###
        Element edition interface
        ###

        startInserting: (p) =>
            insertModel = new PlantElement
                startPoint: p
                text: ''
                fontSize: @settings.get('fontSize')
            @editElementModelPosition = null
            @startEditing(insertModel)

        startUpdating: (elemModel) =>
            # we disable tracking because we temporarily remove the model
            @model.stopTrackingChanges()
            @editElementModelPosition = @model.elements.indexOf(elemModel)
            @model.removeElement(elemModel)
            @startEditing(elemModel)

        startEditing: (elemModel) =>
            # we use reload=true to finish previous edit, if present
            @setMode(EditorMode.EDIT, true)
            @insertView = new EditedElementView
                paper: @paper
                editor: this
                model: elemModel
            @insertView.render()

        finishEditing: (options) =>
            @setDefaultMode()

        # Media

        # click-to-edit text box
        startTextEditing: (textView) =>
            textView.shouldEnterEditMode = true
            @setMode(EditorMode.TEXT_EDIT, true)

        finishTextEditing: (textView) => @setDefaultMode()

        # plant-to-text note
        startPlantToTextMode: (plantToTextModel) ->
            @activePlantToTextObjectId = plantToTextModel.get('objectId')
            @setMode(EditorMode.PLANT_TO_TEXT)

        finishPlantToTextMode: -> @setDefaultMode()

        getActivePlantToTextView: ->
            if not @activePlantToTextObjectId?
                return null
            mediaViews = @getMediaViews()
            for view in mediaViews
                if view.model.get('objectId') == @activePlantToTextObjectId
                    return view
            return null

        ###
        Element views helper functions
        ###

        getSelectableViews: =>
            @getElementViews().concat(@getMediaViews())

        ###
        Selection interface
        ###

        selectChange: => @trigger('selectchange')

        deselectAll: (options) =>
            anySelected = false
            processView = (view) =>
                if view.isSelected()
                    anySelected = true
                    view.select(false, silent: true)
            for name, view of @elementViews
                processView(view)
            for name, view of @mediaViews
                processView(view)
            if options?.silent
                return
            if anySelected
                @trigger('selectchange')

        reselect: (views, options) =>
            selectionChanged = false
            processView = (view) =>
                if view in views
                    if not view.isSelected()
                        selectionChanged = true
                        view.select(true, silent: true)
                else
                    if view.isSelected()
                        selectionChanged = true
                        view.select(false, silent: true)
            for name, view of @elementViews
                processView(view)
            for name, view of @mediaViews
                processView(view)
            if options?.silent
                return
            if selectionChanged
                @trigger('selectchange')

        getElementViewByModelCid: (cid) =>
            _.find @elementViews, (v) -> v?.model?.cid == cid

        getElementByCid: (cid) => @getElementViewByModelCid(cid)?.model

        getSelectedElements: =>
            view.model for name, view of @elementViews when view.isSelected()

        getSelectedElementViews: =>
            view for name, view of @elementViews when view.isSelected()

        getSelectedMedia: =>
            view.model for name, view of @mediaViews when view.isSelected()

        getSelectedMediaViews: =>
            view for name, view of @mediaViews when view.isSelected()

        getSelectedViews: =>
            @getSelectedElementViews()
            .concat(@getSelectedMediaViews())

        selectionBBoxChange: => @trigger('change:selectionBBox')

        getSelectionBBox: =>
            bboxes = (view.getBBox() for view in @getSelectedViews())
            bboxes.push(@insertView.getBBox()) if @insertView?.isSelected()
            BBox.fromBBoxList(bboxes)


        ###
        Letter areas
        ###

        updateDirtyLetterAreas: =>
            for view in @getElementViews()
                if view.letterAreasDirty
                    view.updateLetterAreas()

    class EditorCanvasView extends BaseEditorCanvasView


    class NavigatorCanvasView extends BaseEditorCanvasView

        getNavigatorModeConfig: ->
            startMode: EditorMode.NOOP
            defaultMode: EditorMode.NOOP
            modeSpecs: []

        getModeConfig: -> @getNavigatorModeConfig()

        getMediumViewClass: (model) ->
            if model.get('placementType') == PlacementType.HIDDEN
                null
            else
                super


    module.exports =
        EditorCanvasView: EditorCanvasView
        NavigatorCanvasView: NavigatorCanvasView
