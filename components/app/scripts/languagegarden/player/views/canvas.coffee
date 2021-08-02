    'use strict'

    _ = require('underscore')
    {CanvasView} = require('./../../common/views/canvas')
    {PlayerPlantLinkView} = require('./media/links')
    {PlayerSoundView} = require('./media/sounds')
    {PlayerElementView, ActivePlayerElementView} = require('./elements')
    {
        ActivityType
        CanvasMode
        MediumType
        PlacementType
    } = require('./../../common/constants')
    {MarkBehavior} = require('./../../common/modebehaviors/mark')
    {PlantToTextBehavior} = require('./../../common/modebehaviors/planttotext')


    class PlayerCanvasView extends CanvasView
        className: "#{CanvasView::className} player"

        getElementViewConstructor: (model) ->
            (options) => new PlayerElementView(options)

        getMediumViewClass: (model) ->
            if model.get('placementType') == PlacementType.HIDDEN
                null
            else
                switch model.get('type')
                    when MediumType.SOUND
                        PlayerSoundView
                    when MediumType.PLANT_LINK
                        PlayerPlantLinkView
                    else
                        super

        ###
        Animations
        ###

        getAnimations: (diff, options={}) ->
            helpers = _.extend {}, options.helpers,
                colorPalette: @colorPalette
            opts = _.extend {}, options,
                helpers: helpers
            super(diff, opts)

        settingsKey: -> "player-#{super}"
        metricKey: -> "player-#{super}"


    class ActivityPlayerCanvasView extends PlayerCanvasView

        getElementViewConstructor: (model) ->
            if @controller.isActive()
                (options) => new ActivePlayerElementView(options)
            else
                super

        getActivityClickModeConfig: ->
            startMode: CanvasMode.MARK
            defaultMode: CanvasMode.MARK
            modeSpecs: [
                mode: CanvasMode.MARK
                behaviorClass: MarkBehavior
            ]

        getActivityPlantToTextModeConfig: ->
            startMode: CanvasMode.PLANT_TO_TEXT
            defaultMode: CanvasMode.PLANT_TO_TEXT
            modeSpecs: [
                mode: CanvasMode.PLANT_TO_TEXT
                behaviorClass: PlantToTextBehavior
            ]

        getActivityPlantToTextMemoModeConfig: ->
            startMode: CanvasMode.NOOP
            defaultMode: CanvasMode.NOOP
            modeSpecs: [
                mode: CanvasMode.PLANT_TO_TEXT
                behaviorClass: PlantToTextBehavior
            ]

        getModeConfig: ->
            if @controller.isActive()
                activityType = @controller.dataModel.get('activityType')
                switch activityType
                    when ActivityType.CLICK
                        @getActivityClickModeConfig()
                    when ActivityType.PLANT_TO_TEXT
                        @getActivityPlantToTextModeConfig()
                    when ActivityType.PLANT_TO_TEXT_MEMO
                        @getActivityPlantToTextMemoModeConfig()
                    else
                        @getNoOpModeConfig()
            else
                @getNoOpModeConfig()


    module.exports =
        PlayerCanvasView: PlayerCanvasView
        ActivityPlayerCanvasView: ActivityPlayerCanvasView
