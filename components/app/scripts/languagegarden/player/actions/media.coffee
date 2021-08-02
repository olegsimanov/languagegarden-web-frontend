    'use strict'

    {Action} = require('./../../common/actions/base')
    {MediumType, PlacementType} = require('./../../common/constants')


    class PlayHiddenSound extends Action
        id: 'play-hidden-sound'

        initialize: (options) =>
            super
            @timeline = options.timeline or @controller?.timeline
            @model = options.model or @controller?.model
            @lastMedium = null

        getMetric: => @timeline.getMetric().subMetric("actions.#{@id}")

        getHiddenSoundMedium: ->
            filterMedium = (medium) ->
                (medium.get('type') == MediumType.SOUND and
                 medium.get('placementType') == PlacementType.HIDDEN)
            hiddenSoundMedia = @model.media.filter(filterMedium)
            if hiddenSoundMedia.length > 0
                hiddenSoundMedia[hiddenSoundMedia.length - 1]
            else
                null

        getSoundPlayer: ->
            medium = @getHiddenSoundMedium()
            @controller.getHiddenSoundPlayer(medium)

        perform: ->
            player = @getSoundPlayer()
            if player.isPlaying()
                player.pause()
            else
                player.play()

        isAvailable: -> @getHiddenSoundMedium()?


    module.exports =
        PlayHiddenSound: PlayHiddenSound
