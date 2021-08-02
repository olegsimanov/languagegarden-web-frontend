    'use strict'

    _ = require('underscore')
    Hammer = require('hammerjs')
    utils = require('./../utils')
    {disableSelection} = require('./../domutils')
    {Point} = require('./../../math/points')
    {BaseView} = require('./base')
    {StatefulClassPrototype} = require('./../stateful')


    # this type of button is a DOM div
    class DivButton extends BaseView
        tagName: 'div'
        className: 'button'
        toggledClassName: 'active'
        fadeEffects: false
        disabled: false
        hidden: false
        help: null

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
                # no argument provided - toggle current value
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


    class TooltipButton extends DivButton

        fadeEffects: false
        shouldAppendToContainer: false

        onClick: -> @action.fullPerform()


    ###Inteface for state button.###
    StateButtonViewPrototype =

        __required_interface_methods__: [
            'toggleClass',
        ]

        getStateCssClass: (state) -> "button-state-#{utils.slugify(state)}"
        updateStateCss: (currentState=@currentState) ->
            for st in @states
                @toggleClass(@getStateCssClass(st), st == currentState)

    DivStateButtonBase = DivButton
        .extend(StatefulClassPrototype)
        .extend(StateButtonViewPrototype)

    ###Contains button state handling logic.
    This type of button is a DOM div.
    ###
    class DivStateButton extends DivStateButtonBase

        className: "#{DivButton::className} state-button"

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


    class DivToggleButton extends DivStateButton

        onClick: (e) ->
            @setState(@getNextState())


    ###
    Specific buttons
    ###
    class PunctuationButton extends TooltipButton

        className: "#{TooltipButton::className} punctuation-button"

        initialize: (options) ->
            super
            @templateString = "
                <div class='icon icon_punctuation icon_punctuation_thin'>
                    #{options.action.character}
                </div>"



    module.exports =
        DivButton: DivButton
        DivStateButton: DivStateButton
        DivToggleButton: DivToggleButton
        StateButtonViewPrototype: StateButtonViewPrototype
        TooltipButton: TooltipButton
        PunctuationButton: PunctuationButton
