    'use strict'

    _ = require('underscore')
    {UnitState, LessonData, ActivityData} = require('./../common/models/plants')
    {UnitDataCache} = require('./../common/datacache')
    {preloadMediaFromDataModel} = require('./../common/preload')
    {Timeline} = require('./timeline')
    {SidebarTimeline} = require('./../common/viewmodels/sidebars')
    {Palette} = require('./../common/models/palette')
    {initialTools} = require('./../common/colors')
    {ActivityPlayerCanvasView, PlayerCanvasView} = require('./views/canvas')
    {BaseController} = require('./../common/controllers')
    {KeyListener, MouseListener} = require('./../metrics/listeners')
    {ActivityType} = require('./../common/constants')
    {PlayerPageView} = require('./views/page/base')
    {
        PlantPlayerToolbar
        GenericActivityPlayerToolbar
        MediaActivityPlayerToolbar
        P2TActivityPlayerToolbar
        ActiveActivityPlayerToolbar
        ActiveP2TActivityPlayerToolbar
        ActiveP2TMemoActivityPlayerToolbar
    } = require('./views/toolbars/base')
    {LetterMetrics} = require('./../common/svgmetrics')
    {PlayerTextBoxView} = require('./views/textboxes')
    {PlayerSidebarView} = require('./../player/views/sidebars')
    {PlaybackMode} = require('./constants')
    {getMediaDiffData} = require('./mediacustomdiffs')
    {getActiveClickDiffData} = require('./customdiffs/active_click')
    {
        getActivePlantToTextDiffData
        getActivePlantToTextMemoDiffData
    } = require('./customdiffs/active_plant_to_text')
    {ActivityRecords} = require('./models/activityrecords')
    {PlantTitleView} = require('./../common/views/page/plant_title')
    {SoundPlayer} = require('./../common/mediaplayers')
    {PlayerTitlePageOverlay} = require('./../player/views/overlays/titlepages')
    {Metrics} = require('./../metrics/models/metrics')
    {GoToActivityFromLessonPlayer} = require('./actions/navigation')


    class BasePlayerController extends BaseController
        modelClass: UnitState
        dataModelClass: LessonData
        canvasTimelineButtonClasses: []
        toolbarViewClass: null
        canvasViewClass: PlayerCanvasView
        timelineClass: Timeline
        playbackMode: null

        getToolbarViewClass: -> @toolbarViewClass

        initialize: (options={}) ->
            super

            #languagegarden.settings.debug.enabled
            debugEnabled = options.debugEnabled
            debugEnabled ?= false

            @dataModel = options.dataModel
            @dataModel ?= new @dataModelClass()

            @model = new @modelClass()

            activityRecordsUser = "#{options.userId or 'anonymous'}"

            @activityRecords = options.activityRecords
            @activityRecords ?= ActivityRecords.getRecords(activityRecordsUser)

            @dataCache = UnitDataCache.getInstance()

            palette = new Palette
                toolInfos: initialTools

            @letterMetrics = new LetterMetrics()

            @canvasView = new @canvasViewClass
                controller: this
                model: @model
                dataModel: @dataModel
                debug: debugEnabled
                colorPalette: palette
                letterMetrics: @letterMetrics

            @textBoxView = new PlayerTextBoxView
                controller: this
                model: @model
                dataModel: @dataModel
                debug: debugEnabled
                letterMetrics: @letterMetrics

            @timeline = new @timelineClass
                controller: this
                stateModel: @model
                dataModel: @dataModel
                canvasView: @canvasView
                textBoxView: @textBoxView
                customDiffDataGenerator: @getCustomDiffData
                playbackMode: @playbackMode

            @initializeSidebarTimeline(options)

            @sidebarState = @sidebarTimeline.getSidebarState()

            @sidebarView = new PlayerSidebarView
                controller: this
                sidebarTimeline: @sidebarTimeline

            @view = new PlayerPageView
                canvasView: @canvasView
                subviews: @getPageViewSubviews()
                containerEl: @containerElement

            @canvasView.setParentView(@view)
            @textBoxView.setParentView(@view)
            @sidebarView.setParentView(@view)

            @buttonViews = []

            for cls in @canvasTimelineButtonClasses
                view = new cls
                    parentView: @canvasView
                    controller: this
                    model: @timeline
                @buttonViews.push(view)

            # languagegarden.settings.plantId
            @modelId ?= options.modelId

            @listenTo(@dataModel, 'sync', @onModelSync)
            for evObj in @getEventObjects()
                @listenTo(evObj, 'navigate', @onObjectNavigate)

            @listenTo(@dataCache, 'populate', @onDataCachePopulate)

            @keyListener = new KeyListener(document, @canvasView.getMetric)
            @mouseListener = new MouseListener(document, @canvasView.getMetric)

        initializeSidebarTimeline: (options) ->

            @sidebarTimeline = new SidebarTimeline
                controller: this
                sidebarState: options.sidebarState

        carveOutModelObjects: ->
            dataModel: @dataModel.deepClone()

        getEventObjects: ->
            views = @buttonViews.concat([@view])
            models = [@timeline, @sidebarTimeline]
            models.push(@model) if @model?
            models.push(@dataModel) if @dataModel?
            views.concat(models)

        remove: ->
            objects = @getEventObjects()
            for obj in objects
                @stopListening(obj)
                obj.remove()
            @view = null
            @canvasView = null
            @buttonViews = []
            @model = null
            @dataModel = null
            @timeline = null
            @sidebarTimeline = null
            @keyListener.remove()
            @keyListener = null
            @mouseListener.remove()
            @mouseListener = null
            @letterMetrics.remove()
            @letterMetrics = null
            if @hiddenSoundPlayer
                @hiddenSoundPlayer.remove()
                @hiddenSoundPlayer = null
            super

        getPageViewSubviews: ->
            toolbarViewClass = @getToolbarViewClass()
            viewSubviews =
                '.canvas-container': [@canvasView]
                '.text-to-plant-container': @textBoxView
                '.sidebar-container': [@sidebarView]

            if toolbarViewClass
                @toolbarView = new toolbarViewClass
                    controller: this
                viewSubviews['.toolbar-container'] =  @toolbarView

            viewSubviews

        ###
        Lazily gets the hidden sound player singleton. This player can
        be then shared between multiple views. The medium model
        can be provided later via the sound player .setModel method.
        ###
        getHiddenSoundPlayer: (mediumModel) ->
            player = @hiddenSoundPlayer
            if player?
                player.setModel(mediumModel)
            else
                player = new SoundPlayer
                    bus: @bus
                    model: mediumModel

            @hiddenSoundPlayer = player
            player

        getMetricKey: -> "plant-#{@dataModel.id or 'new'}"

        getMetric: -> Metrics.getMetric(@getMetricKey())

        renderViews: ->
            @view.render()
            # reinitialize scroll after the sidebar view (the subview of
            # this.view) is added to document body
            @sidebarView.reinitializeScroll()
            for view in @buttonViews
                view?.render()

        triggerSyncDataModel: ->
            @trigger('sync:dataModel', this, @dataModel)

        onModelSync: ->
            @timeline.triggerChange()
            @triggerSyncDataModel()
            @renderViews()

        onDataCachePopulate: ->
            for activityId in @dataCache.getActivityIds()
                data = @dataCache.getActivityPayload(activityId)
                if not data?
                    continue
                dataModel = new ActivityData()
                dataModel.set(dataModel.parse(data))
                preloadMediaFromDataModel(dataModel)

            for lessonId in @dataCache.getLessonIds()
                data = @dataCache.getLessonPayload(lessonId)
                if not data?
                    continue
                dataModel = new LessonData()
                dataModel.set(dataModel.parse(data))
                preloadMediaFromDataModel(dataModel)

            return

        setModelId: (modelId, options) ->
            [triggerSuccess, triggerError] = @getTriggeringCallbacks(options)

            if modelId in ['unsaved', 'new']
                modelId = null

            @timeline.pause()

            if ((not modelId? and @dataModel.id?) or
                    (modelId? and not @dataModel.id?) or
                    (modelId? and @dataModel.id? and @dataModel.id != modelId))
                @dataModel.clear(silent: true)
                @dataModel.set('id', modelId, silent: true)
                @dataModel.fetch
                    success: =>
                        @_triggerStart(triggerSuccess, triggerError)
                    error: triggerError
            else
                @timeline.triggerChange()
                triggerSuccess()
                @renderViews()

        ###
        Additional method which can be overriden in subclasses.
        ###
        _triggerStart: (triggerSuccess, triggerError) ->
            triggerSuccess()

        ###
        @param previousPosition optional
        ###
        setStartPosition: (position, previousPosition) ->
            position = position or 0
            @timeline.setupStartPosition(position, previousPosition)

        setSidebarPosition: ->

        setGroovyParent: (parentId, parentPosition) ->
            if parentId?
                @timeline.groovyParent =
                    id: parentId
                    startPosition: parentPosition or 0
            else
                @timeline.groovyParent = null

        setUseKeyframes: (useKeyframes=true) ->
            @timeline.setUseKeyframes(useKeyframes)

        start: (options) ->
            modelId = options?.modelId or @modelId
            @setModelId(modelId, options)

        getCustomDiffData: -> null


    class PlantPlayerController extends BasePlayerController
        toolbarViewClass: PlantPlayerToolbar

        initializeSidebarTimeline: (options) ->
            @sidebarTimeline = new SidebarTimeline
                controller: this
                sidebarState: options.sidebarState
                rootTimeline: @timeline

        setSidebarPosition: (position) ->
            @sidebarTimeline.activateChapterByIndex(position)

        getPageViewSubviews: ->
            viewSubviews = super

            @titlePageView = new PlayerTitlePageOverlay
                controller: this
                timeline: @timeline

            viewSubviews['.toolbar-container'] = []
            viewSubviews['.page-container-inner'] = (
                [@titlePageView].concat(viewSubviews['.page-container-inner'] or [])
            )

            viewSubviews

        getDestinationActivityId: -> @destinationActivityId

        setDestinationActivityId: (activityId, options) ->
            @destinationActivityId = activityId
            if not activityId?
                return
            if not options?.registerAction
                return
            callback = =>
                currentPosition = @timeline.getProgressTime()
                targetPosition = @timeline.getTargetPosition()
                if targetPosition != currentPosition
                    return
                @timeline.off('progresschange', callback)
                action = new GoToActivityFromLessonPlayer
                    controller: this
                    chapterIndex: targetPosition
                    activityRecords: @activityRecords
                    activityId: activityId
                    sidebarTimeline: @sidebarTimeline
                action.fullPerform()
                action.remove()
            @sidebarTimeline.setBlocked(true)
            @timeline.on('progresschange', callback)

        isCachePopulated: (modelId) ->
            @dataCache.getLessonPayload(modelId)? and @dataCache.isReady()

        populateCacheByLessonId: (modelId, options) ->
            if not @dataCache.getLessonPayload(modelId)?
                # Populating this lesson. We put silent: true because the
                # 'populate' event will be triggered later
                # by populateActivitiesByLessonId
                @dataCache.populateLesson(
                    @dataModel.toJSON(unparse: true),
                    silent: true,
                )
                # Populating the activity cache to load the activities faster.
                @dataCache.populateActivitiesByLessonId(modelId, options)
            else
                success = options?.success or ->
                success()

        _triggerStart: (triggerSuccess, triggerError) ->
            modelId = @dataModel.get('id')
            @populateCacheByLessonId modelId,
                success: triggerSuccess
                error: triggerError

        sendRecordToServer: ->
            modelId = @dataModel.get('id')
            # TODO: add getActivityIds method to LessonData model
            activityIds = @sidebarState.getElementsIds()
            @activityRecords.syncByLesson(modelId, activityIds)

        onModelSync: ->
            if @isCachePopulated(@dataModel.get('id'))
                super
                @sendRecordToServer()

            # If cache is not yet populated, we call the super in
            # this.onDataCachePopulate.

        onDataCachePopulate: ->
            super
            # Cache populated, so we call the super from onModelSync.
            BasePlayerController::onModelSync.call(this)
            @sendRecordToServer()


    class ActivityPlayerController extends BasePlayerController
        dataModelClass: ActivityData
        playbackMode: PlaybackMode.SMOOTH
        canvasViewClass: ActivityPlayerCanvasView

        initialize: (options) ->
            super
            @listenTo(@timeline, 'progress:change:end', @onProgressChangeEnd)

        isActive: -> @dataModel.get('active')

        getToolbarViewClass: ->
            activityType = @dataModel.get('activityType')
            if @isActive()
                switch activityType
                    when ActivityType.PLANT_TO_TEXT
                        return ActiveP2TActivityPlayerToolbar
                    when ActivityType.PLANT_TO_TEXT_MEMO
                        return ActiveP2TMemoActivityPlayerToolbar
                    else
                        return ActiveActivityPlayerToolbar
            else
                switch activityType
                    when ActivityType.MEDIA
                        return MediaActivityPlayerToolbar
                    when ActivityType.PLANT_TO_TEXT
                        return P2TActivityPlayerToolbar
                    else
                        # This is used when no activity type is specified
                        # (this happens before the activity model load).
                        return GenericActivityPlayerToolbar

        setParentPlant: (plantId, plantPosition, plantNavType) ->
            if plantId?
                @parentPlant =
                    id: plantId
                    startPosition: plantPosition
                    navType: plantNavType
            else
                @parentPlant = null

        getParentPlantInfo: -> @parentPlant

        onModelSync: ->
            active = @isActive()
            # We need to reload the toolbar view, because after syncing
            # the model activityType changes from undefined to the specific one.
            toolbarViewClass = @getToolbarViewClass()
            @view.removeSubview(@toolbarView)
            @toolbarView = new toolbarViewClass
                controller: this

            @view.subviews['.toolbar-container'] = @toolbarView
            @triggerSyncDataModel()
            @timeline.triggerChange()
            @renderViews()
            entryData =
                activityId: @dataModel.id
                visited: true
            @activityRecords.createInitialEntryByActivityId(@dataModel.id)
            @activityRecords.updateEntry(entryData)
            if active
                # reinitialize modes
                @canvasView.initializeModes()
                if @timeline.getTotalTime() > 0 and not @timeline.isPlaying()
                    @canvasView.setNoOpMode()
                    @toolbarView.setState('no-op')
                    @timeline.once 'progress:change:end', =>
                        # for some reason, we need to reset the canvas state
                        @timeline.setActivityStartState()
                        @canvasView.setDefaultMode()
                        @toolbarView.setState('retry')
                    @timeline.play(false, false)
            else if not @timeline.isPlaying()
                @timeline.play(false, false)

        onProgressChangeEnd: ->
            entryData =
                activityId: @dataModel.id
                seen: true
            if not @isActive()
                entryData.completed = true
            @activityRecords.updateEntry(entryData)
            @sidebarTimeline.setBlocked(false)

        getCustomDiffData: (options) =>
            # onModelSync is fired later
            active = @isActive()
            activityType = @dataModel.get('activityType')
            if active
                switch activityType
                    when ActivityType.CLICK
                        return getActiveClickDiffData(options)
                    when ActivityType.PLANT_TO_TEXT
                        return getActivePlantToTextDiffData(options)
                    when ActivityType.PLANT_TO_TEXT_MEMO
                        return getActivePlantToTextMemoDiffData(options)
            else
                if activityType == ActivityType.MEDIA
                    return getMediaDiffData(options)

            null


    module.exports =
        PlantPlayerController: PlantPlayerController
        ActivityPlayerController: ActivityPlayerController
