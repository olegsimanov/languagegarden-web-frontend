    'use strict'

    _ = require('underscore')
    settings = require('./../../../settings')
    {BaseView} = require('./../base')
    {TooltipButton} = require('./../buttons')


    class ButtonGroup extends BaseView
        buttonViewClass: TooltipButton
        className: 'buttons-group'
        actionSpec: []
        shouldAppendToContainer: true

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'canvasView',
                                    default: @controller?.canvasView,
                                    required: true)
            @setPropertyFromOptions(options, 'model',
                                    default: @controller?.model
                                    required: true)
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


    module.exports =
        ButtonGroup: ButtonGroup
