    'use strict'

    _ = require('underscore')


    class ControllerType

        @PLANT_LIST = 'plant-list'

        @PLANT_BUILDER = 'plant-builder'
        @PLANT_NAVIGATOR = 'plant-navigator'

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

        result = callback(stateModel, timeline)

        stateModel.remove()
        result

    editorRequireDependency = (cb) -> require.ensure([], ((require) ->
        cb(require('../editor/controllers'))
    ), 'editor')

    controllerConfig = [

        type: ControllerType.PLANT_BUILDER
        requireDependency: editorRequireDependency
        controllerName: 'PlantEditorController'
        templatePack: 'editor'
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

    ]

    transitionConfig = [

        startType: ControllerType.PLANT_NAVIGATOR
        endType: ControllerType.PLANT_BUILDER
        endControllerOptions: (options) ->
            editorModelObjects = _.clone(@controller.carveOutModelObjects())
            editorModelObjects.sidebarState = @controller.sidebarState.deepClone()
            dataModel = editorModelObjects.dataModel

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
    ]


    module.exports =
        ControllerType: ControllerType
        controllerConfig: controllerConfig
        transitionConfig: transitionConfig
