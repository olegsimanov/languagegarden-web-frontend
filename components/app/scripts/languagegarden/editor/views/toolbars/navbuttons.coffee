    'use strict'

    _                   = require('underscore')
    {ButtonView}        = require('./../buttons')
    {slugify}           = require('./../../utils')


    navEventBaseName    = 'toolbarnav'
    getNavEventName     = (navTarget) -> "#{navEventBaseName}:#{ slugify(navTarget) }"

    NavButtonPrototype =

        __required_interface_methods__: [
            'isEnabled',
        ]

        navTarget: null
        eventName: null

        triggerToolbarNavEvent:                          -> @trigger(@eventName, @, @navTarget)

        getNavButtonClass: (navTarget=@navTarget)   -> "toolbar-button-#{ slugify(@navTarget) }"
        getNavEventName: (navTarget=@navTarget)     -> getNavEventName(navTarget)

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
        getNavEventName:            getNavEventName
        NavButtonView:              NavButtonView
        BackButtonView:             BackButtonView
        NavButtonPrototype:         NavButtonPrototype
