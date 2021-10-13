    'use strict'

    _ = require('underscore')

    {TooltipButtonView}         = require('./buttons')
    {BaseView}                  = require('./../base')

    {SplitWordElement}          = require('./../../actions/split')
    {DeleteAction}              = require('./../../actions/delete')
    {
        SwitchToRotate
        SwitchToStretch
        SwitchToGroupScale
        SwitchToScale
        SwitchToMove
    }                           = require('./../../actions/modeswitch')
    {StartUpdating}             = require('./../../actions/edit')
    StartUpdatingText           = require('./../../actions/edittext').StartUpdating

    settings                    = require('./../../../settings')

    class ButtonGroupView extends BaseView

        buttonViewClass:            TooltipButtonView
        className:                  'buttons-group'
        actionSpec:                 []
        shouldAppendToContainer:    true

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'canvasView',{ default: @controller?.canvasView }, required: true)
            @setPropertyFromOptions(options, 'model', { default: @controller?.model }, required: true)
            @buttonInfos = (@createButtonInfo(spec) for spec in @actionSpec)
            for buttonInfo in @buttonInfos
                @listenTo(buttonInfo.action, 'change:available', @invalidate)
            @rendered = false
            @prevState = null

        remove: ->
            @stopListening(@canvasView)
            for buttonInfo in @buttonInfos
                buttonInfo.buttonView.remove()
            @canvasView = null
            @model = null
            super

        createButtonInfo: (spec) ->
            action = new spec.actionClass
                controller: @controller
                canvasView: @canvasView

            btnCls = spec.viewClass or @buttonViewClass
            customClassName = "tooltip-button #{spec.className}"

            buttonView = new btnCls
                controller: @controller
                canvasView: @canvasView
                parentView: this
                action: action
                customClassName: customClassName
                help: spec.help

            buttonInfo =
                action: action
                spec: spec
                buttonView: buttonView

            buttonInfo

        renderCore: ->
            state = ({
                available: buttonInfo.action.isAvailable()
            } for buttonInfo in @buttonInfos)

            if _.isEqual(@prevState, state)
                # this condition avoids unnecessary re-inserting button DOM
                # elements into this.el (and killing click events, which
                # is a side effect) when state did not change.
                return

            @$el.empty()
            for i in [0...@buttonInfos.length]
                buttonInfo = @buttonInfos[i]
                st = state[i]
                if not st.available
                    continue
                buttonInfo.buttonView.render()
                @$el.append(buttonInfo.buttonView.el)


            @prevState = state
            @rendered = true

        invalidate: ->
            if @rendered
                @render()
            this


    class SelectionButtonGroupView extends ButtonGroupView

        className: "#{ButtonGroupView::className} buttons-group_selection"

        actionSpec: [
            id:             'switch-to-rotate'
            actionClass:    SwitchToRotate
            className:      'tooltip-switch-to-rotate icon icon_refresh'
            help:           'Switch to rotate'
        ,
            id:             'switch-to-scale'
            actionClass:    SwitchToScale
            className:      'tooltip-switch-to-scale icon icon_scale'
            help:           'Switch to scale'
        ,
            id:             'switch-to-group-scale'
            actionClass:    SwitchToGroupScale
            className:      'tooltip-switch-to-scale icon icon_scale'
            help:           'Switch to scale'
        ,
            id:             'switch-to-move'
            actionClass:    SwitchToMove
            className:      'tooltip-switch-to-move icon icon_move'
            help:           'Switch to move'
        ,
            id:             'switch-to-stretch'
            actionClass:    SwitchToStretch
            className:      'tooltip-switch-to-stretch icon icon_stretch'
            help:           'Switch to stretch'
        ,
            id:             'wordsplit'
            actionClass:    SplitWordElement
            className:      'tooltip-word-split icon icon_scissors'
            help:           'Split word at cursor'
        ,
            id:             'edit'
            actionClass:    StartUpdating
            className:      'tooltip-edit icon icon_pencil'
            help:           'Edit'
        ,
            id:             'edittext'
            actionClass:    StartUpdatingText
            className:      'tooltip-edit'
            help:           'Edit'
        ,
            id:             'delete'
            actionClass:    DeleteAction
            className:      'tooltip-bin icon icon_trash'
            help:           'Delete selected'
        ]


    module.exports =
        SelectionButtonGroupView: SelectionButtonGroupView
