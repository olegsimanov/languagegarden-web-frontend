    'use strict'

    Hammer = require('hammerjs')
    commonElementViews = require('./../../common/views/elements')
    plantUrls = require('./../../common/planturls')

    {ElementView} = commonElementViews
    {getRedirectInfoFromUrl} = plantUrls


    class PlayerElementView extends ElementView

        initialize: (options) ->
            super
            @useLetterAreas = false

        setTextPathProps: ->
            super
            @textPath.setOpacity(@getOpacity())

        getTextPathOptions: ->
            options = super
            options.opacity = @getOpacity()
            options


    class ActivePlayerElementView extends PlayerElementView

        initialize: (options) ->
            super
            @useLetterAreas = true
            @listenTo(@model, 'change', @render)


    module.exports =
        PlayerElementView: PlayerElementView
        ActivePlayerElementView: ActivePlayerElementView
