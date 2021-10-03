    'use strict'

    _ = require('underscore')
    {slugify} = require('./../../utils')
    {DivButton} = require('./../buttons')


    navEventBaseName = 'toolbarnav'
    getNavEventName = (navTarget) ->
        "#{navEventBaseName}:#{ slugify(navTarget) }"

    ToolbarNavButtonPrototype =

        __required_interface_methods__: [
            'isEnabled',
        ]

        navTarget: null
        eventName: null

        triggerToolbarNavEvent: -> @trigger(@eventName, @, @navTarget)

        getNavButtonClass: (navTarget=@navTarget) ->
            "toolbar-button-#{ slugify(@navTarget) }"

        getNavEventName: (navTarget=@navTarget) -> getNavEventName(navTarget)

        initializeNavButton: (options) ->
            @setOptions(options, ['navTarget'], true)
            @setOptions(options, [['eventName', @getNavEventName()]], true)
            @customClassName = @getNavButtonClass()

        navButtonOnClick: ->
            if not @isEnabled()
                return true
            @triggerToolbarNavEvent()


    ###Button that will trigger toolbar nav event when clicked.
    Options:
        navTarget: ideally a string refering to certain toolbar
        eventName/customClassName: both will be generated from navTarget if not
            available in options

    ###
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
        getNavEventName: getNavEventName
        ToolbarNavButton: ToolbarNavButton
        ToolbarBackButton: ToolbarBackButton
        ToolbarNavButtonPrototype: ToolbarNavButtonPrototype
