    'use strict'

    {PageView} = require('./../../../common/views/page/base')


    EditorPageView = class extends PageView

        initialize: (options) ->
            super
            @canvasView = options.canvasView
            @setupEventForwarding(@canvasView, 'navigate')

        remove: ->
            @stopListening(@canvasView)
            delete @canvasView
            super


    module.exports =
        EditorPageView: EditorPageView
