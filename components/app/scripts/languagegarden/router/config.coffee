    'use strict'

    _ = require('underscore')


    class ControllerType

        @PLANT_BUILDER = 'plant-builder'
        @DEFAULT = @PLANT_BUILDER


    editorRequireDependency = (cb) -> require.ensure([], ((require) -> cb(require('../editor/controllers'))), 'editor')

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
            baseUrl + appendage
        routing: [
            routes: [
                'lessons/edit(/)'
                'lessons/edit/:plantId(/)'
            ]
            handler: (plantId) ->
                @controller.setModelId(plantId)
        ]
    ]

    transitionConfig = [

        startType: ControllerType.PLANT_BUILDER
        endType: ControllerType.PLANT_BUILDER
        endControllerOptions: (options) ->
            editorModelObjects = _.clone(@controller.carveOutModelObjects())
            editorModelObjects.sidebarState = @controller.sidebarState.deepClone()
            editorModelObjects

        startControllerOptions: ->
            editorModelObjects = @controller.carveOutModelObjects()
            editorModelObjects.dataModel = null
            _.extend({}, editorModelObjects,
                sidebarState: @controller.sidebarState.deepClone()
            )
    ]


    module.exports =
        ControllerType: ControllerType
        controllerConfig: controllerConfig
        transitionConfig: transitionConfig
