    'use strict'

    _                   = require('underscore')
    {ButtonView}        = require('./buttons')
    {slugify}           = require('./../../utils')


    NavButtonPrototype =

        navTarget: null
        eventName: null

        triggerToolbarNavEvent:                          -> @trigger(@eventName, @, @navTarget)

        getNavButtonClass: (navTarget=@navTarget)   -> "toolbar-button-#{ slugify(@navTarget) }"
        getNavEventName: (navTarget=@navTarget)     -> "toolbarnav:#{ slugify(navTarget) }"

        initializeNavButton: (options) ->
            @setOptions(options, ['navTarget'], true)
            @setOptions(options, [['eventName', @getNavEventName()]], true)
            @customClassName = @getNavButtonClass()

        navButtonOnClick: ->
            if not @isEnabled()
                return true
            @triggerToolbarNavEvent()


    class NavButtonView extends ButtonView.extend(NavButtonPrototype)

        initialize: (options) ->
            @initializeNavButton(options)
            super

        onClick: (e)    => @navButtonOnClick()
        isEnabled:      -> true


    class BackButtonView extends NavButtonView

        navTarget:              'back'
        getNavButtonClass:      -> "#{super} icon icon_back"


    module.exports =
        NavButtonView:              NavButtonView
        BackButtonView:             BackButtonView
        NavButtonPrototype:         NavButtonPrototype
