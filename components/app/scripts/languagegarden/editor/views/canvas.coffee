    'use strict'

    require('raphael')

    Hammer                                  = require('hammerjs')
    _                                       = require('underscore')
    $                                       = require('jquery')

    {BaseView}                              = require('./base')
    {
        EditorElementView,
        EditedElementView}                  = require('./elements')

    {EditorDummyMediumView}                 = require('./media')

    {
        disableSelection
        addSVGElementClass
    }                                       = require('./utils/dom')

    {LetterMetrics}                         = require('./svg/svgmetrics')

    {Settings}                              = require('./../models/settings')
    {PlantElement}                          = require('./../models/elements')

    {
        ColorAction
        RemoveColorAction
        SplitColorAction
    }                                       = require('./../actions/color')

    MoveBehavior                            = require('./behaviors/modes').MoveBehavior
    ColorBehavior                           = require('./behaviors/modes').ColorBehavior
    StretchBehavior                         = require('./behaviors/modes').StretchBehavior
    ScaleBehavior                           = require('./behaviors/modes').ScaleBehavior
    GroupScaleBehavior                      = require('./behaviors/modes').GroupScaleBehavior
    EditBehavior                            = require('./behaviors/modes').EditBehavior
    TextEditBehavior                        = require('./behaviors/modes').TextEditBehavior
    RotateBehavior                          = require('./behaviors/modes').RotateBehavior


    {
        MediumType
        CanvasMode
        CanvasLayers
        ColorMode
    }                                       = require('./../constants')

    {isDarkColor}                           = require('./../utils')

    {BBox}                                  = require('./../math/bboxes')
    {Point}                                 = require('./../math/points')


    class CanvasView extends BaseView

        className: "canvas editor"                          # used by the Backbone.View._ensure function; ensures that the View has a DOM element to render into.

        initialize: (options) ->

            super
            @elementViews   = {}
            @mediaViews     = {}
            @insertView     = null
            @colorPalette   = options.colorPalette

            @setPropertyFromOptions(options, 'dataModel', required: true)

            canvasDimensions    = @getCanvasSetupDimensions()
            @paper              = Raphael(@$el.get(0), canvasDimensions[0], canvasDimensions[1])

            @updateTextDirectionFromModel()
            @$el
                .css
                    'width':    canvasDimensions[0]
                    'height':   canvasDimensions[1]
                .attr('unselectable', 'on')

            @$canvasEl      = $(@paper.canvas)
            @settings       = options.settings or Settings.getSettings("editor-plant-view")
            @letterMetrics  = options.letterMetrics or new LetterMetrics()

            @dragged        = false
            @dragging       = false
            @bgDragging     = false


            @listenTo(@model.elements,  'add',          @onElementAdd)
            @listenTo(@model.elements,  'remove',       @onElementRemove)
            @listenTo(@model.elements,  'reset',        @onElementsReset)

            @listenTo(@model.media,     'add',          @onMediumAdd)
            @listenTo(@model.media,     'remove',       @onMediumRemove)
            @listenTo(@model.media,     'reset',        @onMediaReset)

            @listenTo(@model, 'change:bgColor',         @onBgColorChange)
            @listenTo(@model, 'change:textDirection',   @updateTextDirectionFromModel)

            @listenTo(this,     'selectchange',         @onSelectChange)
            @listenTo(this,     'change:dragging',      (s, v) => @toggleDraggingClass(v))
            @listenTo(this,     'change:bgDragging',    (s, v) => @toggleBgDraggingClass(v))
            @listenTo(this,     'change:mode',          @onModeChange)

            @initializeModes()
            @initializeLayers()
            @initializeBackgroundObject()
            @initializeBackgroundEvents()
            @initializeSelectionRect()
            @initializeEditorEl()

        initializeModes: ->

            cfg             = @getModeConfig()
            @modeBehaviors  = {}
            @mode           = cfg.startMode
            @defaultMode    = cfg.defaultMode or cfg.startMode
            for modeSpec in cfg.modeSpecs
                @addModeBehavior(modeSpec.mode, modeSpec.behaviorClass)

        initializeLayers: ->

            createLayerGuard = (name) =>
                guard = @paper.rect(0, 0, 1, 1)
                disableSelection(guard.node)
                $(guard.node).attr('id', "guard-#{name}")
                guard.hide()
                guard.toFront()
                guard

            @layerGuards                    = {}
            @layerGuards.letters            = createLayerGuard('letters')
            @layerGuards.letterMasks        = createLayerGuard('letter-masks')

            @layerGuards.background         = createLayerGuard('background')
            @layerGuards.letterAreas        = createLayerGuard('letter-areas')
            @layerGuards.selectionRect      = createLayerGuard('selection-rect')
            @layerGuards.selectionTooltip   = createLayerGuard('selection-tooltip')
            @layerGuards.menu               = createLayerGuard('menu')

        initializeBackgroundObject: =>

            @backgroundObj = @paper.rect(0, 0, 1, 1)
            disableSelection(@backgroundObj.node)
            addSVGElementClass(@backgroundObj.node, 'background-area')

            @backgroundObj
                .attr
                    width:  @$canvasEl.attr("width")
                    height: @$canvasEl.attr("height")
                .toBack()
            @backgroundObj.attr
                fill: 'rgba(0,0,0,0)'
                stroke: '#000'
                'stroke-opacity': 0
                'stroke-width': 0

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

            @initializeBackgroundEventsHammer(click, dblclick, drag, dragstart, dragend)
            @putElementToFrontAtLayer(@backgroundObj, CanvasLayers.BACKGROUND)

        initializeSelectionRect: =>
            # initial Raphael objects
            @selectionRectObj = @paper.rect(0, 0, 1, 1)
            addSVGElementClass(@selectionRectObj.node, 'selection-area')
            disableSelection(@selectionRectObj.node)
            @selectionRectObj.hide()
            @putElementToFrontAtLayer(@selectionRectObj, CanvasLayers.SELECTION_RECT)

        initializeEditorEl: =>
            @toggleModeClass()
            @toggleDraggingClass(false)
            @toggleBgDraggingClass(false)


        initializeBackgroundEventsHammer: (click, dblclick, drag, dragstart, dragend) ->

            hammerClick             = (e) => click(e, e.center.x, e.center.y)
            hammerDblClick          = (e) => dblclick(e, e.center.x, e.center.y)
            hammerDrag              = (e) => drag(e, e.deltaX, e.deltaY, e.center.x, e.center.y)
            hammerDragstart         = (e) => dragstart(e, e.center.x, e.center.y)

            Hammer(@backgroundObj.node)
                .on('tap',          hammerClick)
                .on('doubletap',    hammerDblClick)
                .on('hold',         hammerDblClick)
                .on('pan',          hammerDrag)
                .on('panstart',     hammerDragstart)
                .on('panend',       dragend)

        ##########################################################################################################
        #                                        api:reaction to events
        ##########################################################################################################


        onElementAdd: (model, collection, options)      -> @addElementView(model)
        onElementRemove: (model, collection, options)   -> @removeElementView(model)
        onElementsReset: (collection, options)          -> @reloadAllElementViews()

        onMediumAdd: (model, collection, options)       -> @addMediumView(model)
        onMediumRemove: (model, collection, options)    -> @removeMediumView(model)
        onMediaReset: (collection, options)             -> @reloadAllMediaViews()

        onBgColorChange:                                -> @updateBgColor()
        onParentViewBind:                               -> @forwardEventsFrom(@parentView, ("change:pageContainer#{suf}" for suf in ['Transform', 'Scale', 'ShiftX', 'ShiftY']))
        onModeChange:                                   =>

        onSelectChange: =>

            $el                     = $(@el)
            numOfElemSelections     = @getSelectedElements().length
            selectedMediaViews      = @getSelectedMediaViews()
            numOfMediaSelections    = selectedMediaViews.length
            numOfSelections         = @getSelectedViews().length

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

            if @mode == CanvasMode.EDIT
                return

            if @mode == CanvasMode.COLOR
                return

            mode = @defaultMode
            if numOfSelections == 1
                if numOfElemSelections == 1
                    if @getSelectedElements()[0].get('text').length == 1
                        mode = useIfAvailable(CanvasMode.SCALE)
                    else
                        mode = useIfAvailable(CanvasMode.STRETCH)
                else if numOfMediaSelections == 1
                    switch selectedMediaViews[0]?.model.get('type')
                        when MediumType.IMAGE
                            mode = useIfAvailable(CanvasMode.IMAGE_EDIT)
            @setMode(mode)
            @selectionBBoxChange()



        ##########################################################################################################
        #                                           api:mode
        ##########################################################################################################

        getModeConfig:  ->

            startMode: CanvasMode.MOVE
            modeSpecs: [
                mode:           CanvasMode.MOVE
                behaviorClass:  MoveBehavior
            ,
                mode:           CanvasMode.COLOR
                behaviorClass:  ColorBehavior
            ,
                mode:           CanvasMode.STRETCH
                behaviorClass:  StretchBehavior
            ,
                mode:           CanvasMode.SCALE
                behaviorClass:  ScaleBehavior
            ,
                mode:           CanvasMode.GROUP_SCALE
                behaviorClass:  GroupScaleBehavior
            ,
                mode:           CanvasMode.ROTATE
                behaviorClass:  RotateBehavior
            ,
                mode:           CanvasMode.EDIT
                behaviorClass:  EditBehavior
            ,
                mode:           CanvasMode.TEXT_EDIT
                behaviorClass:  TextEditBehavior
            ,
            ]

        addModeBehavior: (mode, behaviorClass) =>
            @modeBehaviors[mode] = new behaviorClass
                controller: @controller
                parentView: this

        getModeBehaviorHandler: (eventName, mode=@mode)     => @modeBehaviors[mode]?.handlers[eventName]

        toggleModeClass: (mode=@mode, flag= true)  => @$el.toggleClass("#{mode.replace(/\s/g,'-')}-mode", flag)

        isModeAvailable: (mode)                             -> @modeBehaviors[mode]?
        getDefaultMode:                                     -> @defaultMode
        setDefaultMode:                                     -> @setMode(@defaultMode)
        restoreDefaultMode: =>
            @deselectAll()
            @setDefaultMode()


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
            leaveHandler(mode) if leaveHandler?
            @toggleModeClass(@mode, false)
            @mode = mode
            @toggleModeClass(@mode, true)
            enterHandler(oldMode) if enterHandler?
            @mode = oldMode
            @setField('mode', mode)

        ##########################################################################################################
        #                                           api:element views
        ##########################################################################################################

        getElementViewConstructor: (model) -> (options) -> new EditorElementView(options)
        getElementViewConstructorOptions: (model) ->
            model:      model
            parentView: this
            paper:      @paper
            editor:     this

        getElementViews:                    => view for name, view of @elementViews
        getSelectedElementViews:            => view for name, view of @elementViews when view.isSelected()
        getElementViewByModelCid: (cid)     => _.find @elementViews, (v) -> v?.model?.cid == cid

        addElementView: (model) ->
            constructor                     = @getElementViewConstructor(model)
            options                         = @getElementViewConstructorOptions(model)
            view                            = constructor(options)
            @elementViews["#{model.cid}"]   = view
            @listenTo(view, 'selectchange', => @trigger('selectchange', view))
            view.render()

        removeElementView: (model) ->
            view = @elementViews["#{model.cid}"]
            wasSelected = view.isSelected()

            @stopListening(view)
            view.remove()
            delete @elementViews["#{model.cid}"]

            if wasSelected then @selectChange()

        removeAllElementViews: ->
            for cid, view of @elementViews
                @stopListening(view)
                view.remove()
            @elementViews = {}

        reloadAllElementViews: ->
            @removeAllElementViews()
            @model.elements.each (model) => @addElementView(model)


        ##########################################################################################################
        #                                           api:media views
        ##########################################################################################################

        getMediumViewClass: (model)                 -> null

        getMediumViewConstructor: (model)           ->
            viewCls = @getMediumViewClass(model) or EditorDummyMediumView
            (options) -> new viewCls(options)

        getMediumViewConstructorOptions: (model)    ->
            model:          model
            parentView:     this
            paper:          @paper
            containerEl:    @el
            editor:         this

        getMediaViews: (mediaTypes)                 =>
            views = (view for name, view of @mediaViews)
            if mediaTypes?
                mediaTypes = [mediaTypes] if _.isString(mediaTypes)
                views = _.filter views, (v) ->
                    v?.model?.get('type') in mediaTypes
            views

        getSelectedMedia:                   => view.model for name, view of @mediaViews when view.isSelected()
        getSelectedMediaViews:              => view for name, view of @mediaViews when view.isSelected()

        addMediumView: (model) ->
            constructor = @getMediumViewConstructor(model)
            options     = @getMediumViewConstructorOptions(model)
            view        = constructor(options)
            @mediaViews["#{model.cid}"] = view
            @listenTo(view, 'selectchange', => @trigger('selectchange', view))
            view.render()

        removeMediumView: (model) ->
            view        = @mediaViews["#{model.cid}"]
            wasSelected = view.isSelected()

            @stopListening(view)
            view.remove()
            delete @mediaViews["#{model.cid}"]

            if wasSelected then @selectChange()

        removeAllMediaViews: ->
            for cid, view of @mediaViews
                @stopListening(view)
                view.remove()
            @mediaViews = {}

        reloadAllMediaViews: ->
            @removeAllMediaViews()
            @model.media.each (model) => @addMediumView(model)

        ##########################################################################################################
        #                                           api:render
        ##########################################################################################################

        render: =>
            @updateBgColor()
            @syncElementViews()
            @syncMediaViews()
            this

        updateBgColor:  -> @$canvasEl.css('backgroundColor', @model.get('bgColor'))

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

        areViewsSynced: (viewsDict, collection)         -> _.isEqual(_.keys(viewsDict), _.pluck(collection.models, 'cid'))


        ##########################################################################################################
        #                                           api:selection
        ##########################################################################################################

        getSelectedElements:                => view.model for name, view of @elementViews when view.isSelected()

        getSelectableViews:                 => @getElementViews().concat(@getMediaViews())
        getSelectedViews:                   => @getSelectedElementViews().concat(@getSelectedMediaViews())

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

        getSelectionBBox: =>
            bboxes = (view.getBBox() for view in @getSelectedViews())
            bboxes.push(@insertView.getBBox()) if @insertView?.isSelected()
            BBox.fromBBoxList(bboxes)

        selectionBBoxChange:                => @trigger('change:selectionBBox')

        ##########################################################################################################
        #                                      api:text direction (do we need it now?)
        ##########################################################################################################


        getTextDirection:               -> @dataModel.get('textDirection') or 'ltr'
        isTextRTL:                      -> @getTextDirection() == 'rtl'
        updateTextDirectionFromModel:   ->

            canvasEl = @paper.canvas

            if @isTextRTL()
                canvasEl.setAttribute('direction', 'rtl')
                canvasEl.setAttribute('unicode-bidi', 'bidi-override')
                canvasEl.setAttribute('writing-mode', 'rl')


        ##########################################################################################################
        #                                           api:editing
        ##########################################################################################################


        startInserting: (p) =>
            insertModel = new PlantElement
                startPoint: p
                text:       ''
                fontSize:   @settings.get('fontSize')
            @editElementModelPosition = null
            @startEditing(insertModel)

        startUpdating: (elemModel) =>
            @model.stopTrackingChanges()
            @editElementModelPosition = @model.elements.indexOf(elemModel)
            @model.removeElement(elemModel)
            @startEditing(elemModel)

        startEditing: (elemModel) =>
            @setMode(CanvasMode.EDIT, true)
            @insertView = new EditedElementView
                paper:  @paper
                editor: this
                model:  elemModel
            @insertView.render()

        startTextEditing: (textView) =>
            textView.shouldEnterEditMode = true
            @setMode(CanvasMode.TEXT_EDIT, true)

        finishEditing: (options) => @setDefaultMode()

        ##########################################################################################################
        #                                           api:dragging
        ##########################################################################################################


        toggleDraggingClass:    (flag=true)     => @$el.toggleClass("in-dragging", flag)
        toggleBgDraggingClass:  (flag=true)     => @$el.toggleClass("in-bg-dragging", flag)
        setDragging:            (dragging)              => @setField('dragging', dragging)
        setBgDragging:          (bgDragging)            => @setField('bgDragging', bgDragging)

        ##########################################################################################################
        #                                           api:color
        ##########################################################################################################

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


        ##########################################################################################################
        #                                       api:helper methods
        ##########################################################################################################

        selectChange:       => @trigger('selectchange')

        setField: (name, value, options) =>
            oldValue = this[name]
            this[name] = value
            if oldValue != value
                @trigger("change", this)
                @trigger("change:#{name}", this, value, oldValue)



        ##########################################################################################################
        #                                           api:other
        ##########################################################################################################


        getChildrenContainerElement:                -> @$el.get(0)
        getCanvasBBox: (absolute)                   => BBox.fromHtmlDOM(@$el, absolute)
        getCanvasSetupDimensions:                   -> [@dataModel.get('canvasWidth'), @dataModel.get('canvasHeight')]
        getCanvasScale:                             -> @parentView.getPageScale()


        transformToCanvasCoords: (x, y)             -> @parentView.transformToCanvasCoords(x, y)
        transformToCanvasCoordOffsets: (dx, dy)     -> @parentView.transformToCanvasCoordOffsets(dx, dy)
        transformToCanvasBBox: (bbox)               -> @parentView.transformToCanvasBBox(bbox)
        transformCanvasToContainerCoords: (x, y)    -> @parentView.transformCanvasToContainerCoords(x, y)



        putElementToFrontAtLayer: (element, layer) ->
            layerGuard = @layerGuards[layer]
            element.insertBefore(layerGuard)

        addCanvasElement: (options) ->
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



        updateDirtyLetterAreas: =>
            for view in @getElementViews()
                if view.letterAreasDirty
                    view.updateLetterAreas()



        remove: =>

            @selectionRectObj.remove()
            @stopListening(this)
            @stopListening(@model)

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




    module.exports =
        CanvasView: CanvasView
