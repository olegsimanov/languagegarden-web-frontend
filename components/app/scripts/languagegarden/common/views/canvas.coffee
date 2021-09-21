    'use strict'

    Hammer = require('hammerjs')
    require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    {enumerate, toIndex} = require('./../utils')
    {
        disableSelection
        addSVGElementClass
        getOffsetRect
    } = require('./../domutils')
    {LetterMetrics} = require('./../svgmetrics')
    {NoOpBehavior} = require('./../modebehaviors/noop')
    {MediumViewBase, DummyMediumView} = require('./media/base')
    {ElementView} = require('./elements')
    {interpolateColor} = require('./../interpolations/colors')
    {interpolateOpacity} = require('./../interpolations/base')
    {splitDiff} = require('./../diffs/utils')
    {OperationType} = require('./../diffs/operations')
    {Point} = require('./../../math/points')
    {BBox} = require('./../../math/bboxes')
    {PlantMedium} = require('./../models/media')
    {BaseView} = require('./base')
    {
        MediumType
        TextSize
        PlacementType
        CanvasLayers
        CanvasMode
    } = require('./../constants')
    {Settings} = require('./../models/settings')
    {TextToPlantView} = require('./media/text_to_plant')
    {
        isElementSplitDiff
        isElementSplitReversedDiff
    } = require('./../autokeyframes')


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

            # word configuration
            @settings = options.settings or Settings.getSettings(@settingsKey())

            @debug = if options?.debug? then options.debug else false

            # metrics
            @letterMetrics = options.letterMetrics or new LetterMetrics()

            # listening on model events
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
            # order of calling is important here. the last call is the
            # topmost.
            @layerGuards.images = createLayerGuard('images')
            @layerGuards.letters = createLayerGuard('letters')
            @layerGuards.letterMasks = createLayerGuard('letter-masks')

            #interaction layers
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
            # the background object was already created in plant view

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
            # this fill is important, without it
            # the background rect will be 'empty'
            @backgroundObj.attr
              fill: 'rgba(0,0,0,0)'
              stroke: '#000'
              'stroke-opacity': 0
              'stroke-width': 0

        initializeModes: ->
            # setting up mode behaviors
            cfg = @getModeConfig()
            @modeBehaviors = {}
            @mode = cfg.startMode
            @defaultMode = cfg.defaultMode or cfg.startMode
            @addModeBehavior(CanvasMode.NOOP, NoOpBehavior)
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

        ###
        Mode behavior interface
        ###

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
            # changing @mode to mode for proper context for enterHandler
            @mode = mode
            @toggleModeClass(@mode, true)
            enterHandler(oldMode) if enterHandler?
            # temporary changing @mode back to oldMode because we want to
            # properly trigger the 'change' events
            @mode = oldMode
            @setField('mode', mode)

        setDefaultMode: -> @setMode(@defaultMode)

        setNoOpMode: -> @setMode(CanvasMode.NOOP)

        ###
        Background rect helpers
        ###

        updateBgColor: ->
            @$canvasEl.css('backgroundColor', @model.get('bgColor'))

        ###
        Canvas helpers
        ###

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

        ###
        Editor Fields interface
        ###

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

        ###
        Adding/Removing/Resetting elements helpers
        ###

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

        ###
        Adding/Removing/Resetting media helpers
        ###

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

        ###
        Event handlers
        ###

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

        ###
        Element views helper functions
        ###

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

        ###
        This method re-creates the view if necessary. In other cases
        it falls back to the default behavior, which is just calling
        render() method of view.
        ###
        renderView: (view, previousModelData) ->
            model = view.model
            oldType = previousModelData.type
            newType = model.get('type')
            if model instanceof PlantMedium and oldType != newType
                # the media types do not match, re-instatiating
                # the view may be necessary.
                @removeMediumView(model)
                # this.addMediumView already calls render()
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



    module.exports =
        CanvasView: CanvasView
