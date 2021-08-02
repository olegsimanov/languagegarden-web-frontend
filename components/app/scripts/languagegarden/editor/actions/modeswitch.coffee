    'use strict'

    _ = require('underscore')
    {Action} = require('./base')
    {EditorMode} = require('./../constants')


    ###Base class, contains isAvailable conditions.###
    class ModeSwitchAction extends Action

        storeMetric: ->
            # suppress storing metrics of mode switch actions
            # this is much better done in the editor

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

        multipleWordsSelected: -> @canvasView.getSelectedElements().length > 1

        mediaSelected: -> @canvasView.getSelectedMediaViews().length > 0

        ###Multiple words and no media selected.###
        multipleWordsNoMediaSelected: ->
            @multipleWordsSelected() and not @mediaSelected()


    class ModeSwitchActionSingleMode extends ModeSwitchAction

        # EditorMode value this action will switch to
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

        ###Actual action-specific isAvailable check.###
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
        SwitchToRotate: SwitchToRotate
        SwitchToStretch: SwitchToStretch
        SwitchToScale: SwitchToScale
        SwitchToGroupScale: SwitchToGroupScale
        SwitchToMove: SwitchToMove
