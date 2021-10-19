    'use strict'

    _                                   = require('underscore')
    jQuery                              = require('jquery')
    Backbone                            = require('backbone')

    {ICanForwardEvents}                 = require('./../events')
    {ICanMakePropertyFromOptions}       = require('./../properties')
    {capitalize}                        = require('./../utils')

    {
        visibilityOpacityMap
        markedOpacityMap
    }                                   = require('./../../editor/constants')

    buildMixinWithProperty = (propName) ->

        bindHandlerName     = "on#{capitalize(propName)}Bind"
        unbindHandlerName   = "on#{capitalize(propName)}Unbind"

        setterName          = "set#{capitalize(propName)}"

        proto               = {}
        proto[setterName]   = (value, options={}) ->

            silent  = options.silent or false
            force   = options.force or false

            if value == @[propName] and not force
                return this

            if @[propName]? and not silent
                @[unbindHandlerName](options)

            @[propName] = value

            if @[propName]? and not silent
                @[bindHandlerName](options)

            this

        proto[bindHandlerName]      = ->
        proto[unbindHandlerName]    = -> @stopListening(@[propName])
        proto

    BaseViewCore = Backbone.View
        .extend(ICanForwardEvents)
        .extend(ICanMakePropertyFromOptions)
        .extend(buildMixinWithProperty('parentView'))
        .extend(buildMixinWithProperty('model'))
        .extend(buildMixinWithProperty('controller'))


    class BaseView extends BaseViewCore

        shouldAppendToContainer:    false

        getBindablePropertyNames:   -> [ 'parentView', 'model', 'controller'  ]

        constructor: (options) ->
            bindablePropertyNames = @getBindablePropertyNames()
            for propName in bindablePropertyNames
                @setProperty(propName, options[propName], constructor: true, silent: true)
            super
            for propName in bindablePropertyNames
                @onPropertyInitialBind(propName)

        initialize: (options={}) ->
            super
            for propName in @getBindablePropertyNames()
                @setProperty(propName, options[propName], initialize: true, silent: true)

        remove: ->
            for propName in @getBindablePropertyNames()
                @setProperty(propName, null)
            super

        setProperty: (propName, value, options) ->
            setterName = "set#{capitalize(propName)}"
            @[setterName](value, options)

        onPropertyInitialBind: (propName, options) ->
            if @[propName]?
                binderName = "on#{capitalize(propName)}Bind"
                @[binderName](options)



        setOption: (options, name, defaultVal, isRequired=false, optName, normalizer) ->
            optName ?= name
            normalizer ?= _.identity
            @[name] = normalizer(options[optName]) if options[optName]?
            @[name] ?= defaultVal if defaultVal?
            if isRequired and not @[name]?
                console.error("Missing required attribute: #{name}")

        setOptions: (options, specs, requiredAttributes=[]) =>
            if _.isBoolean(requiredAttributes)
                isRequired = -> true
            else if _.isArray(requiredAttributes)
                isRequired = (name) -> name in requiredAttributes
            else
                isRequired = -> false

            for name in specs
                if _.isArray(name)
                    [name, defaultVal] = name
                else if _.isString(name)
                    defaultVal = undefined

                @setOption(options, name, defaultVal, isRequired(name))




        getContainerEl:             -> _.result(@, 'containerEl') or (_.result(@, 'containerView') or _.result(@, 'parentView'))?.el

        appendToContainerIfNeeded: ->
            if _.result(this, 'shouldAppendToContainer')
                @$el.appendTo(@getContainerEl())

        onParentViewUnbind:         -> super

        renderCore:                 ->

        render:                     ->
                                        @renderCore()
                                        @appendToContainerIfNeeded()
                                        this

        invalidate:                 -> @render()



    class PlantChildView extends BaseView

        setCoreOpacity: (opacity)   ->

        getModelOpacity:            ->

                                        marked = @model.get('marked')
                                        if marked in [true, false]
                                            opacity = markedOpacityMap[marked]
                                        else
                                            opacity = visibilityOpacityMap[@model.get('visibilityType')]
                                        opacity ?= 1.0
                                        opacity

        getOpacity:                 ->  @getModelOpacity()

        updateVisibility:           -> @setCoreOpacity(@getOpacity())


    module.exports =
        BaseView:           BaseView
        PlantChildView:     PlantChildView
