'use strict'

_ = require('underscore')
{VisibilityType, MediumType} = require('./../../common/constants')
{BaseModeBehavior} = require('./base')
{TextToPlantLetterClickBehavior} = require('./../letterbehaviors/planttotext')


class PlantToTextBehavior extends BaseModeBehavior
    boundLettersClasses: [
        TextToPlantLetterClickBehavior,
    ]
    middleLettersClasses: [
        TextToPlantLetterClickBehavior,
    ]

    ###Returns VisibilityType that should be set based on selection state
    and given editor mode.
    @param selected If the view should be marked as selected.
    @param inPlantToTextMode If views should be marked for PLANT_TO_TEXT
        editor mode.
    ###
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

    isActiveModelInPlantToTextMode: ->
        model = @getActiveModel()
        model?.get('inPlantToTextMode') or false

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


module.exports =
    PlantToTextBehavior: PlantToTextBehavior
