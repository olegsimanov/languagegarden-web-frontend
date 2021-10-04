    'use strict'

    _ = require('underscore')
    Backbone = require('backbone')
    jQuery = require('jquery')
    {
        visibilityOpacityMap
        markedOpacityMap
    } = require('./../../editor/constants')
    {extend, extendAll} = require('./../extend')
    {EventForwardingPrototype} = require('./../events')
    {
        buildPropertySupportPrototype
        PropertySetupPrototype
    } = require('./../properties')
    {capitalize} = require('./../utils')


    BaseViewCore = Backbone.View
        .extend(EventForwardingPrototype)
        .extend(PropertySetupPrototype)
        .extend(buildPropertySupportPrototype('parentView'))
        .extend(buildPropertySupportPrototype('model'))
        .extend(buildPropertySupportPrototype('controller'))


    class BaseView extends BaseViewCore

        @extend:    extend
        @extendAll: extendAll

        shouldAppendToContainer: false

        propertyConfig: [ { name: 'controller' }, { name: 'model' }, { name: 'parentView'} ]

        constructor: (options) ->
            bindablePropertyNames = @getBindablePropertyNames()
            for propName in bindablePropertyNames
                @setProperty(propName, options[propName],
                             constructor: true, silent: true)
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

        getBindablePropertyNames: -> _.pluck(@propertyConfig, 'name')

        setProperty: (propName, value, options) ->
            setterName = "set#{capitalize(propName)}"
            @[setterName](value, options)

        onPropertyInitialBind: (propName, options) ->
            if @[propName]?
                binderName = "on#{capitalize(propName)}Bind"
                @[binderName](options)


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

        setOption: (options, name, defaultVal, isRequired=false, optName, normalizer) ->
            optName ?= name
            normalizer ?= _.identity
            @[name] = normalizer(options[optName]) if options[optName]?
            @[name] ?= defaultVal if defaultVal?
            if isRequired and not @[name]?
                console.error("Missing required attribute: #{name}")

        getContainerEl: -> _.result(@, 'containerEl') or (_.result(@, 'containerView') or _.result(@, 'parentView'))?.el

        appendToContainerIfNeeded: ->
            if _.result(this, 'shouldAppendToContainer')
                @$el.appendTo(@getContainerEl())

        onParentViewUnbind: ->
            super

        renderCore: ->

        render: ->
            @renderCore()
            @appendToContainerIfNeeded()
            this

        invalidate: -> @render()


    class PlantChildView extends BaseView

        setCoreOpacity: (opacity) ->

        getModelOpacity: ->
            marked = @model.get('marked')
            if marked in [true, false]
                opacity = markedOpacityMap[marked]
            else
                opacity = visibilityOpacityMap[@model.get('visibilityType')]
            opacity ?= 1.0
            opacity

        getOpacity: ->
            @getModelOpacity()

        updateVisibility: ->
            @setCoreOpacity(@getOpacity())


    module.exports =
        BaseView: BaseView
        PlantChildView: PlantChildView
