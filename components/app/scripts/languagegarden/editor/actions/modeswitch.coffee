    'use strict'

    _               = require('underscore')
    {Action}        = require('./base')
    {EditorMode}    = require('./../constants')


    class ModeSwitchAction extends Action

        isInMode: (mode=@mode) -> @canvasView.mode == mode

        singleMultiLetterWordSelected: ->
            els = @canvasView.getSelectedElements()
            (
                els.length == 1 and
                els[0]?.get('text').length > 1 and
                not @mediaSelected()
            )

        singleOneLetterWordSelected: ->
            els = @canvasView.getSelectedElements()
            (
                els.length == 1 and
                els[0]?.get('text').length == 1 and
                not @mediaSelected()
            )

        multipleWordsSelected:          -> @canvasView.getSelectedElements().length > 1
        mediaSelected:                  -> @canvasView.getSelectedMediaViews().length > 0
        multipleWordsNoMediaSelected:   -> @multipleWordsSelected() and not @mediaSelected()


    class ModeSwitchActionSingleMode extends ModeSwitchAction

        mode: null

        initialize: (options) ->
            super
            @id = "mode-switch-#{@mode}"

        initializeListeners: ->
            @listenTo(@canvasView, 'change:mode', @onModeChange)
            @listenTo(@canvasView, 'change:selectionBBox', @onSelectionChange)

        perform: =>
            @canvasView.setMode(@mode)
            true

        isToggled: => @isInMode()

        isAvailable: => @canApplyToSelection()

        canApplyToSelection: =>

        onModeChange: ->
            @triggerAvailableChange()
            @triggerToggledChange()

        onSelectionChange: ->
            @triggerAvailableChange()


    class SwitchToRotate extends ModeSwitchActionSingleMode
        mode: EditorMode.ROTATE

        canApplyToSelection: =>
            @singleOneLetterWordSelected() or @multipleWordsNoMediaSelected()


    class SwitchToStretch extends ModeSwitchActionSingleMode
        mode: EditorMode.STRETCH

        canApplyToSelection: => @singleMultiLetterWordSelected()


    class SwitchToScale extends ModeSwitchActionSingleMode
        mode: EditorMode.SCALE

        canApplyToSelection: =>
            not @mediaSelected() and @canvasView.getSelectedElements().length == 1


    class SwitchToGroupScale extends ModeSwitchActionSingleMode
        mode: EditorMode.GROUP_SCALE

        canApplyToSelection: =>
            not @mediaSelected() and @canvasView.getSelectedElements().length > 1


    class SwitchToMove extends ModeSwitchActionSingleMode
        mode: EditorMode.MOVE

        canApplyToSelection: => @multipleWordsNoMediaSelected()


    module.exports =
        SwitchToRotate:         SwitchToRotate
        SwitchToStretch:        SwitchToStretch
        SwitchToScale:          SwitchToScale
        SwitchToGroupScale:     SwitchToGroupScale
        SwitchToMove:           SwitchToMove
