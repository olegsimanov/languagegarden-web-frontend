    'use strict'

    _ = require('underscore')
    MediumSelectBehavior = require('./../mediabehaviors/select').SelectBehavior
    MediumMoveBehavior = require('./../mediabehaviors/move').MoveBehavior
    MediumEditBehavior = require('./../mediabehaviors/edit').EditBehavior

    {VisibilityType, MediumType} = require('./../constants')
    {BaseModeBehavior} = require('./base')
    {TextToPlantLetterClickBehavior} = require('./../letterbehaviors/planttotext')

    class PlantToTextBehavior extends BaseModeBehavior
        boundLettersClasses: [
            TextToPlantLetterClickBehavior,
        ]
        middleLettersClasses: [
            TextToPlantLetterClickBehavior,
        ]

        getVisibilityType = (selected, inPlantToTextMode=true) ->
            visibility = VisibilityType.VISIBLE
            if not selected and inPlantToTextMode
                visibility = VisibilityType.PLANT_TO_TEXT_FADED
            visibility

        @getVisibilityType: getVisibilityType

        getActiveModel: ->
            if not @activeObjectId
                mediaModel = @model.media.findByAttribute('type')(MediumType.PLANT_TO_TEXT_NOTE)
                return mediaModel
            @model.media.findByObjectId(@activeObjectId)

        setActiveModelPlantToTextMode: (flag) ->
            model = @getActiveModel()
            if not model?
                return
            oldFlag = model.get('inPlantToTextMode')
            if flag != oldFlag
                model.set('inPlantToTextMode', flag)
                @parentView.render()

        retrieveActiveObjectId: -> @parentView.activePlantToTextObjectId

        onModeEnter: (oldMode) ->
            @model.stopTrackingChanges()
            @activeObjectId = @retrieveActiveObjectId()

            super
            @setActiveModelPlantToTextMode(true)

            @model.startTrackingChanges()

        onModeReset: ->
            @model.stopTrackingChanges()

            @setActiveModelPlantToTextMode(false)
            @activeObjectId = @retrieveActiveObjectId()
            @setActiveModelPlantToTextMode(true)

            @model.startTrackingChanges()

        onModeLeave: (newMode) ->
            @model.stopTrackingChanges()

            @setActiveModelPlantToTextMode(false)

            delete @parentView.activePlantToTextObjectId
            delete @activeObjectId
            super

            @model.startTrackingChanges()

    class EditorPlantToTextBehavior extends PlantToTextBehavior
        mediaClasses: [
            MediumSelectBehavior,
            MediumMoveBehavior,
            MediumEditBehavior,
        ]


    module.exports =
        PlantToTextBehavior: EditorPlantToTextBehavior
