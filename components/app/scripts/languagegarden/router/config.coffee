    'use strict'

    _ = require('underscore')


    class ControllerType

        @PLANT_LIST = 'plant-list'

        @PLANT_BUILDER = 'plant-builder'
        @PLANT_NAVIGATOR = 'plant-navigator'

        @DEFAULT = @PLANT_LIST


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
