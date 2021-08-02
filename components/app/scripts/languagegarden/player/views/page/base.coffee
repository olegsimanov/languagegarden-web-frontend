    'use strict'

    {PageView} = require('./../../../common/views/page/base')


    class PlayerPageView extends PageView

        initialize: (options) ->
            super
            @canvasView = options.canvasView
            @setupEventForwarding(@canvasView, 'navigate')

        remove: ->
            @stopListening(@canvasView)
            delete @canvasView
            super


    module.exports =
        PlayerPageView: PlayerPageView
