    'use strict'

    _ = require('underscore')

    {Point} = require('./../../../math/points')
    {BBox} = require('./../../../math/bboxes')
    {SoundPlayer} = require('./../../mediaplayers')
    {SvgMediumView} = require('./base')
    {addSVGElementClass, disableSelection} = require('./../../domutils')


    SoundView = class extends SvgMediumView
        width: 62
        height: 62

        initialize: (options) =>
            super(options)
            @iconObj = null
            @player = null
            @listenTo(@model, 'change:url', @onModelChange)
            @listenTo(@model, 'change:urls', @onModelChange)

        remove: =>
            @unsetPlayer()
            @iconObj?.remove()
            @stopListening(@model)
            super

        getBBox: =>
            BBox.fromCenterPoint(@model.get('centerPoint'),
                                 new Point(@width * 0.5, @height * 0.5))

        intersects: (bbox) => @getBBox().intersects(bbox)

        getIconUrl: =>
            "#{settings.staticUrl}img/3/lg_player1.png"

        render: =>
            center = @model.get('centerPoint')
            x = center.x - @width * 0.5
            y = center.y - @height * 0.5
            width = @width
            height = @height
            if @iconObj?
                @iconObj.attr
                    src: @getIconUrl()
                    x: x
                    y: y
                    width: width
                    height: height
            else
                @iconObj = @paper.image(@getIconUrl(), x, y, width, height)
                addSVGElementClass(@iconObj.node, 'medium')
                disableSelection(@iconObj.node)
                # for some reason, using domutils disableSelection is not enough
                # when applied on SVG image. therefore we use preventDefault
                # on click/drag using standard raphael event system
                @iconObj.click((e) -> e.preventDefault())
                @iconObj.drag(((dx,dy,x,y,e) -> e.preventDefault()),
                              ((x,y,e) -> e.preventDefault()))
                @toFront()
                @bindIconEvents()

            this

        putIconToFront: =>
            @iconObj?.toFront()

        toFront: => @putIconToFront()

        bindIconEvents: =>

        getPlayer: =>
            if not @player?
                @player = new SoundPlayer
                    model: @model
                @listenTo(@player, 'playbackchange', @onPlaybackChange)
            @player

        unsetPlayer: =>
            if @player?
                @stopListening(@player)
                @player.remove()
                @player = null

        onPlaybackChange: (player) =>
            @trigger('playbackchange', player, this)

        onModelChange: =>
            # we have to lazy reload the player.
            # TODO: in the future the player
            # should do that automatically without recreating him.
            @unsetPlayer()


    module.exports =
        SoundView: SoundView
