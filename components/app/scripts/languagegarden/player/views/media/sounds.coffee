    'use strict'

    Hammer = require('hammerjs')
    _ = require('underscore')
    settings = require('./../../../settings')
    {SoundView} = require('./../../../common/views/media/sounds')


    PlayerSoundView = class extends SoundView

        initialize: (options) ->
            super
            # listening on this because this.player may be changing
            @listenTo(this, 'playbackchange', @onPlaybackChange)
            @iconUrl = @getIconUrlForPlayer(null)

        remove: ->
            @stopListening(this)
            super

        onClick: =>
            player = @getPlayer()
            if player.isPlaying()
                player.pause()
            else
                player.play()

        bindIconEvents: =>
            Hammer(@iconObj.node, @hammerEventOptions)
                .on("tap", @onClick)

        getIconUrlForPlayer: (player) ->
            if player?.isPlaying()
                "#{settings.staticUrl}img/3/lg_player_pause.png"
            else
                "#{settings.staticUrl}img/3/lg_player1.png"

        getIconUrl: -> @iconUrl

        onPlaybackChange: (player) =>
            oldIconUrl = @iconUrl
            @iconUrl = @getIconUrlForPlayer(player)
            if oldIconUrl != @iconUrl
                @render()


    module.exports =
        PlayerSoundView: PlayerSoundView
