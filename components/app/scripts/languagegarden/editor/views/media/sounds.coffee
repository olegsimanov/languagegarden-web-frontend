    'use strict'

    _ = require('underscore')
    mathPoints = require('./../../../math/points')
    commonSoundViews = require('./../../../common/views/media/sounds')
    editorConstants = require('./../../constants')
    commonProgressBars = require('./../../../common/views/progress/bars')
    editorViewsBase = require('./base')
    commonViewsBase = require('./../../../common/views/media/base')

    {Point} = mathPoints
    {SoundView} = commonSoundViews
    {EditorLayers} = editorConstants
    {SoundProgressBar} = commonProgressBars


    ExtendedSoundView = SoundView
        .extend(editorViewsBase.SelectablePrototype)
        .extend(commonViewsBase.SVGStylablePrototype)
        .extend(editorViewsBase.EventDispatchingPrototype)
        .extend(editorViewsBase.EventBindingPrototype)


    EditorSoundView = class extends ExtendedSoundView
        initialize: (options) =>
            super
            @editor = options.editor
            @listenTo(@editor, 'change:dragging', @render)
            @listenTo(@editor, 'change:pageContainerTransform', @renderProgressBar)

        remove: =>
            @stopListening(this)
            @stopListening(@editor)
            @progressBar?.remove()
            super

        getElementNode: => @iconObj.node

        putIconToFront: =>
            if @iconObj?
                @editor.putElementToFrontAtLayer(@iconObj,
                                                 EditorLayers.LETTER_AREAS)

        bindIconEvents: => @bindClickableElementEvents()

        renderProgressBar: =>
            if not @progressBar?
                @progressBar = new SoundProgressBar
                    parentView: @editor

            centerPoint = @model.get('centerPoint')
            # the sound progress bar is anchored in the container, therefore
            # we need to change the coordinate system
            [x, y] = @editor.transformCanvasToContainerCoords(centerPoint.x
                                                              centerPoint.y)
            containerCenterPoint = new Point(x, y)
            @progressBar.position = containerCenterPoint.add
                x: -100
                y: @width/2 + 10

            if @isSelected() and not @editor.dragging
                # lazy load the sound player (ensure that progress bar has
                # the current player)
                @getPlayer()
                @progressBar.hidden = false
            else
                @progressBar.hidden = true
            @progressBar.render()

        render: =>
            super
            @renderProgressBar()
            this

        select: (options) =>
            result = super
            @renderProgressBar()
            result

        unsetPlayer: =>
            super
            @progressBar?.setSoundPlayer(null)

        getPlayer: =>
            player = super
            @progressBar?.setSoundPlayer(player)
            player


    module.exports =
        EditorSoundView: EditorSoundView
