    'use strict'

    _ = require('underscore')
    buttons = require('./views/buttons')
    historyActions = require('./actions/history')
    deleteActions = require('./actions/delete')
    {UnitState, ActivityData, LessonData} = require('./../common/models/plants')
    {Timeline} = require('./timeline')
    editorColors = require('./colors')
    settings = require('./../settings')
    {EditorPalette} = require('./models/palette')
    {
        EditorCanvasView
        NavigatorCanvasView
        ActivityIntroEditorCanvasView
        ActivityModeEditorCanvasView
    } = require('./views/canvas')
    {TextBoxView} = require('./../common/views/textboxes')
    {EditorTextBoxView} = require('./views/textboxes')
    {BaseController} = require('./../common/controllers')
    {History} = require('./history')
    {ActivityType} = require('./../common/constants')
    {EditorPageView} = require('./views/page/base')
    {NavigationToolbar} = require('./views/toolbars/navigator')
    {BuilderToolbar} = require('./views/toolbars/builder')
    {
        P2TActivityEditorToolbar
        ClickActivityEditorToolbar
        DictionaryActivityEditorToolbar
        ActivityIntroEditorToolbar
        ActivityModeEditorToolbar
    } = require('./views/toolbars/activities')
    {Settings} = require('./../common/models/settings')
    {LetterMetrics} = require('./../common/svgmetrics')
    {ToolbarEnum} = require('./../common/views/toolbars/constants')
    {StationTimeline} = require('./../common/viewmodels/stationprogress')
    {BaseCollection} = require('./../common/models/base')
    {SidebarTimeline} = require('./../common/viewmodels/sidebars')
    {TitlePageOverlay} = require('./views/overlays/titlepages')


    class BaseEditorController extends BaseController
        modelClass: UnitState
        dataModelClass: LessonData
        historyClass: History
        timelineClass: Timeline
        ToolbarEnum: ToolbarEnum
        buttonClasses: []
        canvasViewClass: EditorCanvasView
        textBoxViewClass: EditorTextBoxView

        showSettings: true
        getShowSettings: -> @showSettings

        shortcutsAndActionsClasses: [
            ['Ctrl+Z', historyActions.Undo],
            ['Ctrl+Y', historyActions.Redo],
            ['Delete', deleteActions.DeleteAction],
        ]

        toolbarViewClass: null
        getToolbarViewClass: -> @toolbarViewClass

        initialize: (options={}) ->
            super
            @draggingInfo = {}

            #languagegarden.settings.debug.enabled
            debugEnabled = options.debugEnabled
            debugEnabled ?= false
            @dataModel = options.dataModel
            @dataModel ?= new @dataModelClass()
            @model = new @modelClass()

            editorPalette = new EditorPalette
                toolInfos: editorColors.initialTools
                newWordColor: editorColors.newWordColor

            @history = options.history
            @history ?= new @historyClass
                model: @model

            @timeline = new @timelineClass
                controller: this
                stateModel: @model
                dataModel: @dataModel
                history: @history
                diffPosition: options.diffPosition

            @stationTimeline = new StationTimeline
                timeline: @timeline

            settingsModel = Settings.getSettings('plant-view')

            @letterMetrics = new LetterMetrics()

            @canvasView = new @canvasViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                history: @history
                debug: debugEnabled
                settings: settingsModel
                colorPalette: editorPalette
                letterMetrics: @letterMetrics

            @listenTo(@canvasView, 'change:dragging', @onCanvasDraggingChange)
            @listenTo(@canvasView, 'change:bgDragging',
                      @onCanvasBgDraggingChange)

            # for deprecated usage
            @editorView = @canvasView

            @textBoxView = new @textBoxViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                debug: debugEnabled
                settings: settingsModel
                letterMetrics: @letterMetrics

            @initializeSidebarTimeline(options)

            if not settings.isMobile
                #TODO: handle optional dependencies
                editorKeyboard = require('./keyboard')

                @shortcutListener = new editorKeyboard.ShortcutListener
                    el: document.body

                for [shortcut, actionCls] in _.result(this,
                                                'shortcutsAndActionsClasses')
                    @shortcutListener.on(shortcut, new actionCls(
                        controller: this))

            toolbarViewClass = @getToolbarViewClass()
            @toolbarView = new toolbarViewClass
                controller: @

            @view = new EditorPageView
                controller: this
                canvasView: @canvasView
                subviews: @getPageViewSubviews()
                containerEl: @containerElement

            @canvasView.setParentView(@view)
            @textBoxView.setParentView(@view)

            @modelId = options.modelId
            @listenTo(@dataModel, 'sync', @onModelSync)
            for evObj in @getEventObjects()
                @listenTo(evObj, 'navigate', @onObjectNavigate)

        initializeSidebarTimeline: (options) ->

            @sidebarTimeline = new SidebarTimeline
                controller: this
                sidebarState: options.sidebarState
                blocked: true

        getPageViewSubviews: ->
            '.toolbar-container': @toolbarView
            '.canvas-container': [@canvasView]
            '.text-to-plant-container': @textBoxView

        ###
        This method is used for 'carving out' model data from controller,
        which allows reusing model & history objects in the editor when
        we return from the test player.
        ###
        carveOutModelObjects: ->
            dataModel: @dataModel.deepClone()
            diffPosition: @timeline.getDiffPosition()

        getEventObjects: ->
            views = [@view]
            views.push(@settingsView) if @settingsView?
            models = [@timeline, @stationTimeline]
            models.push(@history) if @history?
            models.push(@model) if @model?
            models.push(@dataModel) if @dataModel?
            views.concat(models)

        remove: ->
            for obj in @getEventObjects()
                @stopListening(obj)
                obj.remove()
            @shortcutListener?.remove()
            @timeline = null
            @stationTimeline = null
            @model = null
            @dataModel = null
            @canvasView = null
            @view = null
            @letterMetrics.remove()
            @letterMetrics = null
            super

        renderViews: ->
            @view.render()
            # reinitialize scroll after the sidebar view (the subview of
            # this.view) is added to document body

        onModelSync: ->
            @renderViews()

        setModelId: (modelId, options) ->
            [triggerSuccess, triggerError] = @getTriggeringCallbacks(options)

            if modelId in ['unsaved', 'new']
                modelId = null
            else if _.isString(modelId)
                modelId = parseInt(modelId, 10)

            oldModelId = @dataModel.id

            if ((not modelId? and oldModelId?) or
                    (modelId? and not oldModelId?) or
                    (modelId? and oldModelId? and oldModelId != modelId))
                if modelId?
                    loadModelOptions =
                        success: triggerSuccess
                        error: triggerError
                    @timeline.loadModel(modelId, loadModelOptions)
                else
                    @timeline.createEmptyModel()
                    triggerSuccess()
                    @renderViews()
            else
                triggerSuccess()
                @renderViews()

        start: (options) ->
            modelId = options?.modelId or @modelId
            @setModelId(modelId, options)

        isDragging: ->
            (@draggingInfo.canvasElements or
                @draggingInfo.canvasBackground or false)

        setToolbarState: (state) ->
            if not state?
                state = @toolbarView.defaultState
            @toolbarView.setState(state)

        getDestinationActivityId: -> null

        onCanvasDraggingChange: (source, value) ->
            oldDragging = @isDragging()
            @draggingInfo.canvasElements = value
            dragging = @isDragging()
            if oldDragging != dragging
                @trigger('change:dragging', this, dragging, oldDragging)

        onCanvasBgDraggingChange: (source, value) ->
            oldDragging = @isDragging()
            @draggingInfo.canvasBackground = value
            dragging = @isDragging()
            if oldDragging != dragging
                @trigger('change:dragging', this, dragging, oldDragging)


    class PlantEditorController extends BaseEditorController
        shortcutsAndActionsClasses: BaseEditorController::shortcutsAndActionsClasses.concat([
            ['Ctrl+Alt+S', historyActions.Save],
        ])

        toolbarViewClass: BuilderToolbar

        initializeSidebarTimeline: (options) ->
            @sidebarTimeline = new SidebarTimeline
                controller: this
                sidebarState: options.sidebarState
                rootTimeline: @timeline
                blocked: true


    class PlantNavigatorController extends PlantEditorController
        canvasViewClass: NavigatorCanvasView
        textBoxViewClass: TextBoxView
        toolbarViewClass: NavigationToolbar

        initialize: (options)->
            @currentActivityLinks = new BaseCollection()
            super
            @activityLinksCollectionReplace()
            @listenTo(
                @model, 'diffpositionchange sync', @activityLinksCollectionReplace
            )

        initializeSidebarTimeline: (options) ->
            @sidebarTimeline = new SidebarTimeline
                controller: this
                sidebarState: options.sidebarState
                rootTimeline: @timeline
                blocked: false


        remove: ->
            @detachActivityLinksCollection()

            @currentActivityLinks.off()
            @currentActivityLinks = null

            @stopListening(@toolbarView)
            super

        detachActivityLinksCollection: =>
            if @activityLinksCollection?
                @stopListening(@activityLinksCollection)
                @activityLinksCollection = null

        activityLinksCollectionReplace: =>
            @detachActivityLinksCollection()

            @activityLinksCollection = @timeline.getCurrentActivityLinksCollection()

            if @activityLinksCollection?
                @listenTo(
                    @activityLinksCollection, 'all',
                    @onActivityLinksUpdate
                )

            @onActivityLinksUpdate()

        onActivityLinksUpdate: =>
            @currentActivityLinks.set(@activityLinksCollection?.models or [])

        onModelSync: ->
            navInfo =
                trigger: false
                type: 'nav-plant'
                plantId: @dataModel.id

            @trigger('navigate', this, navInfo)
            @renderViews()

        getPageViewSubviews: =>
            @titlePageView = new TitlePageOverlay
                controller: this
                timeline: @timeline

            views = super
            # we place the title page view at the level of plant container
            # because we need access to the toolbar (unlike the player)
            views['.plant-container'] = [
                @titlePageView
            ].concat(views['.plant-container'] or [])

            views


    class ActivityEditorController extends BaseEditorController
        dataModelClass: ActivityData

        getShowSettings: ->
            @dataModel.get('activityType') in [ActivityType.DICTIONARY]

        getToolbarViewClass: ->
            activityType = @dataModel.get('activityType')
            switch activityType
                when ActivityType.PLANT_TO_TEXT
                    return P2TActivityEditorToolbar
                when ActivityType.PLANT_TO_TEXT_MEMO
                    return P2TActivityEditorToolbar
                when ActivityType.CLICK
                    return ClickActivityEditorToolbar
                when ActivityType.DICTIONARY
                    return DictionaryActivityEditorToolbar
                else
                    console.log("No toolbar view defined for ActivityType:
                        #{activityType}")


    ###
    For passive/active choice
    ###
    class ActivityModeEditorController extends BaseEditorController
        dataModelClass: ActivityData
        canvasViewClass: ActivityModeEditorCanvasView

        getShowSettings: -> false

        getToolbarViewClass: -> ActivityModeEditorToolbar


    class ActivityIntroEditorController extends BaseEditorController
        dataModelClass: ActivityData
        canvasViewClass: ActivityIntroEditorCanvasView

        getShowSettings: -> false

        getToolbarViewClass: -> ActivityIntroEditorToolbar


    module.exports =
        PlantEditorController:          PlantEditorController
        PlantNavigatorController:       PlantNavigatorController
        ActivityEditorController:       ActivityEditorController
        ActivityIntroEditorController:  ActivityIntroEditorController
        ActivityModeEditorController:   ActivityModeEditorController
