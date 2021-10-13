    'use strict'

    _                           = require('underscore')
    Hammer                      = require('hammerjs')

    {StatefulClassPrototype}    = require('./stateful')
    {BaseView}                  = require('./../base')
    {disableSelection}          = require('./../utils/dom')
    utils                       = require('./../../utils')
    {ColorMode}                 = require('./../../constants')
    {Point}                     = require('./../../math/points')
    navigationActions           = require('./../../actions/navigation')
    settings                    = require('./../../../settings')



    class ButtonView extends BaseView

        tagName:            'div'
        className:          'button'
        toggledClassName:   'active'
        fadeEffects:        false
        disabled:           false
        hidden:             false
        help:               null

        initialize: (options) ->
            super

            @initializeProperties(options)

            if @action? or @actionClass?
                @initializeAction(options)

            @$el.attr('title', @help) if @help?

            @onClick ?= (event) =>
                event.preventDefault()
                console.error('unsupported button click!')

            Hammer(@el).on('tap', (event) => @onClick(event))

            @delegateEvents()
            disableSelection(@el)

        initializeProperties: (options) ->
            @setOption(options, 'parentEl', @parentView?.el)
            @setOption(options, 'position', null, false, null, Point.fromValue)
            @setOption(options, 'width')
            @setOption(options, 'height')
            @setOption(options, 'customClassName')
            @setOption(options, 'templateString')
            @setOption(options, 'hidden', null, false, 'show', (x) -> not x)
            @setOption(options, 'hidden')
            @setOption(options, 'disabled')
            @setOption(options, 'fadeEffects')
            @setOption(options, 'onClick')
            @setOption(options, 'help')
            @setOption(options, 'action')
            @setOption(options, 'actionClass')

        initializeAction: (options) ->
            @action ?= new @actionClass(@getActionOptions(options))
            @customClassName ?= "button #{ @action.id }-button"
            @help ?= @action.getHelpText()
            @onClick ?= (event) =>
                if not @action.isAvailable()
                    return true
                event.preventDefault()
                @action.fullPerform()
            @listenTo(@action, 'change:available', @render)
            @listenTo(@action, 'change:toggled', @render)

        getActionOptions: ->
            controller: @controller

        remove: =>
            delete @onClick
            super

        isToggled: -> @action?.isToggled() or false

        isEnabled: ->
            enabled = @action?.isAvailable()
            enabled ?= not @disabled
            enabled

        isDisabled: -> not @isEnabled()

        render: =>
            @delegateEvents()
            if @customClassName?
                @$el.addClass(@customClassName)

            @$el.html(_.result(@, 'templateString')) if @templateString?
            @toggleVisibility(not @hidden)
            @$el.toggleClass('disabled', @isDisabled())
            @$el.css(@getElCss())
            @$el.toggleClass(@toggledClassName, @isToggled())
            @appendToContainerIfNeeded()
            this

        getElCss: =>
            elCss = {}
            elCss.left = @position.x if @position?
            elCss.top = @position.y if @position?
            elCss.width = @width if @width?
            elCss.height = @height if @height?
            elCss

        toggleVisibility: (show) =>
            if show?
                @hidden = not show
            else
                @hidden = not @hidden

            if @hidden
                if @fadeEffects
                    @$el.fadeOut('fast')
                else
                    @$el.addClass('hide')
            else
                if @fadeEffects
                    @$el.fadeIn('fast')
                else
                    @$el.removeClass('hide')

        hide: => @toggleVisibility(false)

        show: => @toggleVisibility(true)


    class TooltipButtonView extends ButtonView

        fadeEffects: false
        shouldAppendToContainer: false

        onClick: -> @action.fullPerform()

    class EditorButtonView extends ButtonView

        initialize: (options) ->
            # pass model from options.controller so BaseView can use set it
            if options?
                options.model ?= options?.controller?.model
            # TODO: this limits any inheriting view to append directly to the
            # editor or break the getEditor reference.
            options.parentView = options.editor if options?.editor?
            super(options)
            # the this.editor field is deprecated. please use this.getEditor()
            # instead.
            @editor = @parentView

        getEditor: -> @parentView


    class MenuActionButtonView extends EditorButtonView

        modelListenEventName: 'editablechange'

        initialize: (options) =>
            super
            @disabled = not @isEnabled()
            @hidden = @isHidden()
            if options.modelListenEventName?
                @modelListenEventName = options.modelListenEventName
            @listenTo(@parentView.model, @modelListenEventName, @onChange)

        remove: ->
            @stopListening(@parentView.model)
            super

        getActionOptions: (options) ->
            controller: options.controller
            parentView: @parentView

        isEnabled: -> @action.isAvailable()
        isToggled: -> @action.isToggled()
        isHidden:   -> false

        onChange: =>
            @disabled = not @isEnabled()
            @hidden = @isHidden()
            @$el.toggleClass('toggled', @isToggled())
            @render()

        onClick: (event) =>
            if not @isEnabled()
                return true
            event.preventDefault()
            @action.fullPerform()

    ##########################################################################################################
    #                                        stateful buttons
    ##########################################################################################################


    StateButtonViewPrototype =

        getStateCssClass: (state) -> "button-state-#{utils.slugify(state)}"
        updateStateCss: (currentState=@currentState) ->
            for st in @states
                @toggleClass(@getStateCssClass(st), st == currentState)

    StateButtonBaseView = ButtonView
        .extend(StatefulClassPrototype)
        .extend(StateButtonViewPrototype)

    class StateButtonView extends StateButtonBaseView

        className: "#{ButtonView::className} state-button"

        initialize: (options) ->
            super
            @setupStates(options)
            @listenTo(@, 'change:state', @onStateChange)

        toggleClass: (cls, isEnabled) -> @$el.toggleClass(cls, isEnabled)

        remove: =>
            @stopListening(@)
            super

        render: =>
            super
            @updateStateCss()
            @

        onStateChange: (sender, value, options) =>
            @render()


    class ToggleButtonView extends StateButtonView

        onClick: (e) -> @setState(@getNextState())


    class EditorToggleButtonView extends ToggleButtonView

        initialize: (options) ->
            options.parentView = options.editor if options?.editor?
            super

        getEditor: -> @parentView

    class EditorColorModeButtonView extends EditorToggleButtonView

        className:      "color-mode-button #{EditorToggleButtonView::className}"
        states:         [ColorMode.WORD, ColorMode.LETTER]
        defaultState:   ColorMode.DEFAULT

        initialize: (options) =>
            super
            @model = options.model
            @editor = options.editor
            @setState(@model.get('colorMode'))
            @listenTo(@model, 'change:colorMode', @onColorModeChange)

        onColorModeChange: (sender, value) => @setState(value)

        remove: =>
            @stopListening(@model)
            delete @model
            delete @editor
            super

        render: =>
            super

        onClick: =>
            super
            @model.set('colorMode', @currentState)

    module.exports =
        ButtonView:                 EditorButtonView
        TooltipButtonView:          TooltipButtonView
        EditorToggleButtonView:     EditorToggleButtonView
        EditorColorModeButtonView:  EditorColorModeButtonView
