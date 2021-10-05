    'use strict'

    _               = require('underscore')
    {DivButton}     = require('./../buttons')
    {slugify}       = require('./../../utils')


    navEventBaseName = 'toolbarnav'
    getNavEventName = (navTarget) ->
        "#{navEventBaseName}:#{ slugify(navTarget) }"

    ToolbarNavButtonPrototype =

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


    class ToolbarNavButton extends DivButton.extend(ToolbarNavButtonPrototype)

        initialize: (options) ->
            @initializeNavButton(options)
            super

        onClick: (e) => @navButtonOnClick()
        isEnabled: -> true


    class ToolbarBackButton extends ToolbarNavButton

        navTarget: 'back'

        getNavButtonClass: -> "#{super} icon icon_back"


    module.exports =
        getNavEventName:            getNavEventName
        ToolbarNavButton:           ToolbarNavButton
        ToolbarBackButton:          ToolbarBackButton
        ToolbarNavButtonPrototype:  ToolbarNavButtonPrototype
