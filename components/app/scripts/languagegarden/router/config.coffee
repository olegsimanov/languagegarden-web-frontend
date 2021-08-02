    'use strict'

    _ = require('underscore')


    class ControllerType
        @PLANT_LIST = 'plant-list'

        @PLANT_BUILDER = 'plant-builder'
        @PLANT_NAVIGATOR = 'plant-navigator'

        @ACTIVITY_INTRO_CREATOR = 'activity-intro-creator'
        @ACTIVITY_CREATOR = 'activity-creator'
        @ACTIVITY_MODE_CREATOR = 'activity-mode-creator'

        @PLANT_PLAYER = 'plant-player'
        @PASSIVE_ACTIVITY_PLAYER = 'passive-activity-player'
        @ACTIVE_ACTIVITY_PLAYER = 'active-activity-player'

        @DEFAULT = @PLANT_LIST


    toPosition = (str) ->
        if str?
            parseInt(str, 10)
        else
            str

    ###
    Introduces the changes in given dataModel by constructing temporary
    state model (and timeline object).

    The given callback receives the state model, which can be manipulated
    freely and all changes on it will be tracked in the given data model.
    the callback receives also the timeline object so the data model can
    be saved correctly.
    ###
    tapStateChanges = (controller, dataModel, callback) ->
        stateModel = new controller.modelClass()
        history = new controller.historyClass
            model: stateModel

        timeline = new controller.timelineClass
            controller: controller
            stateModel: stateModel
            dataModel: dataModel
            history: history

        result = callback(stateModel, timeline)

        timeline.remove()
        history.remove()
        stateModel.remove()
        result


    ###
    Add newly created activity to given dataModel at (optional) diffPosition
    if it was saved.
    ###
    addSavedActivity = (controller, dataModel, activityData, diffPosition) ->
        if not activityData.id?
            return

        tapStateChanges controller, dataModel, (stateModel, timeline) ->

            if diffPosition?
                timeline.rewind(diffPosition)

            timeline.addActivityLink
                activityId: activityData.id

            timeline.saveModel()


    listRequireDependency = (cb) -> require.ensure([], ((require) ->
        cb(require('../list/controllers'))
    ), 'list')

    editorRequireDependency = (cb) -> require.ensure([], ((require) ->
        cb(require('../editor/controllers'))
    ), 'editor')

    playerRequireDependency = (cb) -> require.ensure([], ((require) ->
        cb(require('../player/controllers'))
    ), 'player')


    controllerConfig = [
        type: ControllerType.PLANT_LIST
        requireDependency: listRequireDependency
        controllerName: 'ListController'
        templatePack: 'plant_list'
        navInfoTypes: ['list-plants']
        urlGenerator: (navInfo) ->
            pageNumber = if navInfo.pageNumber > 0 then navInfo.pageNumber else 1
            "/lessons/list/page/#{pageNumber}/"
        routing: [
            routes: [
                'lessons(/)'
                'lessons/list(/)'
                'lessons/list/page/:pageNumber(/)'
            ]
            handler: (pageNumber) ->
                @controller.setPageNumber(pageNumber)
        ]
    ,

        type: ControllerType.PLANT_PLAYER
        requireDependency: playerRequireDependency
        controllerName: 'PlantPlayerController'
        templatePack: 'player'
        hasEditorModelsObjects: true
        navInfoTypes: ['play-lesson', 'play-plant', 'test-play-plant']
        urlGenerator: (navInfo) ->
            plantId = navInfo.plantId or 'unsaved'
            baseUrl = "/lessons/play/#{plantId}/"
            appendage = ''
            if navInfo.startPosition?
                # casting to string
                startPosition = "#{navInfo.startPosition}"
                previousPosition = "#{navInfo.previousPosition}"
                appendage = "pos/#{startPosition}/"
                if (previousPosition? and previousPosition != startPosition)
                    appendage += "#{previousPosition}/"
                else if navInfo.activityId
                    appendage += "#{startPosition}/"
            if navInfo.groovy
                appendage = "groovy/#{navInfo.groovyParentId}/"
                if navInfo.groovyParentPosition > 0
                    appendage += "pos/#{navInfo.groovyParentPosition}/"
            if navInfo.activityId
                appendage += "activity/#{navInfo.activityId}/"
            baseUrl + appendage
        routing: [
            routes: [
                'lessons/play/:id(/)'
                'lessons/play/:id/pos/:position(/)'
                'lessons/play/:id/pos/:position/:previousPosition(/)'
                'lessons/play/:id/pos/:position/:previousPosition/activity/:activityId(/)'
            ]
            handler: (id, position, previousPosition, activityId) ->
                position = toPosition(position)
                previousPosition = toPosition(previousPosition)
                activityId = toPosition(activityId)
                @controller.setDestinationActivityId(activityId, registerAction: true)
                @controller.setStartPosition(position, previousPosition)
                @controller.setModelId(id)
        ]
    ,

        type: ControllerType.PASSIVE_ACTIVITY_PLAYER
        requireDependency: playerRequireDependency
        controllerName: 'ActivityPlayerController'
        templatePack: 'player'
        hasEditorModelsObjects: true
        navInfoTypes: ['play-activity-passive', 'play-activity']
        urlGenerator: (navInfo) ->
            plant = navInfo.parentPlant or {}
            plantId = plant.id or 'unsaved'
            plantPosition = plant.startPosition or 0
            baseUrl = "/activities/play-passive/#{navInfo.activityId}"
            plantNavType = plant.navType or 'play-lesson'
            navSourceMapping =
                'play-plant': 'from-player'
                'play-lesson': 'from-player'
                'nav-plant': 'from-nav'
            fromNavType = navSourceMapping[plantNavType]
            appendage = "/#{fromNavType}/#{plantId}/#{plantPosition}/"
            baseUrl + appendage
        routing: [
            routes: [
                'activities/play-passive/:activityId/from-nav/:plantId/:plantPosition(/)'
            ]
            handler: (activityId, plantId, plantPosition) ->
                plantPosition = toPosition(plantPosition)
                @controller.sidebarTimeline.setBlocked(true)
                @controller.setParentPlant(plantId, plantPosition, 'nav-plant')
                @controller.setStartPosition(0)
                @controller.setModelId(activityId)
        ,
            routes: [
                'activities/play-passive/:activityId/from-player/:plantId/:plantPosition(/)'
            ]
            handler: (activityId, plantId, plantPosition) ->
                plantPosition = toPosition(plantPosition)
                @controller.sidebarTimeline.setBlocked(true)
                @controller.setParentPlant(plantId, plantPosition, 'play-lesson')
                @controller.setStartPosition(0)
                @controller.setModelId(activityId)
        ]
    ,

        type: ControllerType.PLANT_BUILDER
        requireDependency: editorRequireDependency
        controllerName: 'PlantEditorController'
        templatePack: 'editor'
        hasHistory: true
        navInfoTypes: ['edit-plant']
        urlGenerator: (navInfo) ->
            plantId = navInfo.plantId or 'unsaved'
            baseUrl = "/lessons/edit/#{plantId}/"
            appendage = ''
            if navInfo.newStation
                if navInfo.stationIndex?
                    appendage = "duplicate-station/#{navInfo.stationIndex}/"
                else
                    appendage = 'new-station/'
            baseUrl + appendage
        routing: [
            routes: [
                'lessons/edit(/)'
                'lessons/edit/:plantId(/)'
            ]
            handler: (plantId) ->
                @controller.setModelId(plantId)
        ,

            routes: [
                'lessons/edit/:plantId/new-station(/)'
            ]
            optionsFromArgs: (plantId) ->
                newStation: true
            handler: (plantId) ->
                @controller.setModelId(plantId)
        ,

            routes: [
                'lessons/edit/:plantId/duplicate-station/:stationIndex(/)'
            ]
            optionsFromArgs: (plantId, stationIndex) ->
                newStation: true
                stationIndex: stationIndex
            handler: (plantId) ->
                @controller.setModelId(plantId)
        ]
    ,

        type: ControllerType.PLANT_NAVIGATOR
        requireDependency: editorRequireDependency
        controllerName: 'PlantNavigatorController'
        templatePack: 'editor'
        hasHistory: true
        navInfoTypes: ['nav-plant', 'nav-plant-activities']
        urlGenerator: (navInfo) ->
            plantId = navInfo.plantId or 'unsaved'
            baseUrl = "/lessons/nav/#{plantId}/"
            if navInfo.type == 'nav-plant-activities'
                "#{baseUrl}activities/"
            else
                baseUrl
        routing: [
            routes: [
                'lessons/nav(/)'
                'lessons/nav/:id(/)'
            ]
            handler: (id) ->
                @controller.setModelId(id)
        ,
            routes: [
                'lessons/nav/activities(/)'
                'lessons/nav/:id/activities(/)'
            ]
            handler: (id) ->
                @controller.setModelId(id)
                @controller.toolbarView.setState(
                    @controller.ToolbarEnum.ACTIVITY_CHOICE
                )
        ]
    ,

        type: ControllerType.ACTIVITY_INTRO_CREATOR
        requireDependency: editorRequireDependency
        controllerName: 'ActivityIntroEditorController'
        templatePack: 'editor'
        navInfoTypes: ['add-activity']
        urlGenerator: (navInfo) ->
            plantId = navInfo.plantId or 'unsaved'
            "/activities/add-intro/#{plantId}/"
        routing: [
            routes: [
                'activities/add-intro/:plantId(/)'
            ]
            optionsFromArgs: (plantId) ->
                plantId: plantId
            handler: (plantId) ->
                @controller.start()
        ]
    ,

        type: ControllerType.ACTIVITY_CREATOR
        requireDependency: editorRequireDependency
        controllerName: 'ActivityEditorController'
        templatePack: 'editor'
        navInfoTypes: ['add-activity-next']
        urlGenerator: (navInfo) ->
            plantId = navInfo.plantId or 'unsaved'
            "/activities/add/#{plantId}/#{navInfo.activityType}/"
        routing: [
            routes: [
                'activities/add/:plantId/:type(/)'
            ]
            optionsFromArgs: (plantId, activityType) ->
                activityType: activityType
                plantId: plantId
            handler: (plantId, activityType) ->
                @controller.start()
        ]
    ,

        type: ControllerType.ACTIVITY_MODE_CREATOR
        requireDependency: editorRequireDependency
        controllerName: 'ActivityModeEditorController'
        templatePack: 'editor'
        navInfoTypes: ['add-activity-final']
        urlGenerator: (navInfo) ->
            plantId = navInfo.plantId or 'unsaved'
            "/activities/add-mode/#{plantId}/"
        routing: [
            routes: [
                'activities/add-mode/:plantId(/)'
            ]
            handler: (plantId) ->
                @controller.start()
        ]
    ]


    transitionConfig = [
        startType: ControllerType.PLANT_NAVIGATOR
        endType: ControllerType.PLANT_PLAYER
        endControllerOptions: ->
            @editorModelObjects = @controller.carveOutModelObjects()
            modelCopy = @editorModelObjects.model.deepClone()
            modelCopy.rewindAtEnd()
            model: modelCopy

        startControllerOptions: ->
            controllerOptions = @editorModelObjects
            @editorModelObjects = null
            controllerOptions
    ,

        startType: ControllerType.PLANT_NAVIGATOR
        endType: ControllerType.PLANT_BUILDER
        endControllerOptions: (options) ->
            editorModelObjects = _.clone(@controller.carveOutModelObjects())
            editorModelObjects.sidebarState = @controller.sidebarState.deepClone()
            dataModel = editorModelObjects.dataModel
            if options.newStation
                tapStateChanges @controller, dataModel, (stateModel, timeline) ->

                    timeline.capWithStation()

                if options.stationIndex?
                    stationPositions = dataModel.getAllStationPositions()
                    stationPos = stationPositions[options.stationIndex]
                    dataModel.duplicateState(stationPos)

            editorModelObjects

        startControllerOptions: ->
            editorModelObjects = @controller.carveOutModelObjects()
            # we resetting the data model to force it to reload
            # this is the easiest way to restore the data model if someone
            # discarded the changes done in the builder
            editorModelObjects.dataModel = null
            _.extend({}, editorModelObjects,
                sidebarState: @controller.sidebarState.deepClone()
            )
    ,

        startType: ControllerType.PLANT_NAVIGATOR
        endType: ControllerType.ACTIVITY_INTRO_CREATOR
        endControllerOptions: (options) ->

            @editorModelObjects = @controller.carveOutModelObjects()
            activityData = @editorModelObjects.dataModel.cloneActivityTemplate
                diffPosition: @editorModelObjects.diffPosition

            dataModel: activityData
            sidebarState: @controller.sidebarState.deepClone()
        startControllerOptions: (options) ->
            activityEditorModelObjects = @controller.carveOutModelObjects()
            activityData = activityEditorModelObjects.dataModel

            if @editorModelObjects?
                {dataModel, diffPosition} = @editorModelObjects
                addSavedActivity(@controller, dataModel, activityData,
                                 diffPosition)

            controllerOptions = _.clone(@editorModelObjects)
            controllerOptions.sidebarState = @controller.sidebarState.deepClone()
            @editorModelObjects = null
            controllerOptions
    ,

        startType: ControllerType.ACTIVITY_INTRO_CREATOR
        endType: ControllerType.ACTIVITY_CREATOR
        endControllerOptions: (options) ->
            activityType = options.activityType
            activityEditorModelObjects = @controller.carveOutModelObjects()

            activityData = activityEditorModelObjects.dataModel

            tapStateChanges @controller, activityData, (stateModel, timeline) ->

                timeline.capWithStation()
                activityData.set('activityType', activityType)
                stateModel.setupActivity
                    activityType: activityType

            dataModel: activityData
            sidebarState: @controller.sidebarState.deepClone()
    ,

        startType: ControllerType.ACTIVITY_CREATOR
        endType: ControllerType.ACTIVITY_MODE_CREATOR
        endControllerOptions: (options) ->
            dataModel: @controller.dataModel.deepClone()
            sidebarState: @controller.sidebarState.deepClone()
    ,

        startType: ControllerType.PLANT_NAVIGATOR
        endType: ControllerType.ACTIVITY_MODE_CREATOR
        startControllerOptions: (options) ->
            activityEditorModelObjects = @controller.carveOutModelObjects()
            activityData = activityEditorModelObjects.dataModel

            if @editorModelObjects?
                {dataModel, diffPosition} = @editorModelObjects
                addSavedActivity(@controller, dataModel, activityData,
                                 diffPosition)

            controllerOptions = _.clone(@editorModelObjects)
            controllerOptions.sidebarState = @controller.sidebarState.deepClone()
            @editorModelObjects = null
            controllerOptions
    ,

        startType: ControllerType.PLANT_PLAYER
        endType: ControllerType.PASSIVE_ACTIVITY_PLAYER
        endControllerOptions: ->
            sidebarState: @controller.sidebarState.deepClone()

        startControllerOptions: ->
            sidebarState: @controller.sidebarState.deepClone()
    ,

        startType: ControllerType.PLANT_NAVIGATOR
        endType: ControllerType.PASSIVE_ACTIVITY_PLAYER
        endControllerOptions: ->
            sidebarState: @controller.sidebarState.deepClone()
        startControllerOptions: ->
            sidebarState: @controller.sidebarState.deepClone()
    ]


    module.exports =
        ControllerType: ControllerType
        controllerConfig: controllerConfig
        transitionConfig: transitionConfig
