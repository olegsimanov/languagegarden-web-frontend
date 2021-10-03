    'use strict'

    _ = require('underscore')
    Backbone = require('backbone')
    jQuery = require('jquery')
    {
        visibilityOpacityMap
        markedOpacityMap
    } = require('./../../editor/constants')
    {extend, extendAll} = require('./../../common/extend')
    {EventForwardingPrototype} = require('./../../common/events')
    {
        buildPropertySupportPrototype
        PropertySetupPrototype
    } = require('./../../common/properties')
    {capitalize} = require('./../../common/utils')


    BaseViewCore = Backbone.View
    .extend(EventForwardingPrototype)
    .extend(PropertySetupPrototype)
    .extend(buildPropertySupportPrototype('parentView'))
    .extend(buildPropertySupportPrototype('model'))
    .extend(buildPropertySupportPrototype('controller'))


    class BaseView extends BaseViewCore

        @extend: extend

        @extendAll: extendAll

        shouldAppendToContainer: false

        propertyConfig: [
            name: 'controller'
        ,
            name: 'model'
        ,
            name: 'parentView'
        ]

        constructor: (options) ->
            bindablePropertyNames = @getBindablePropertyNames()
            for propName in bindablePropertyNames
                @setProperty(propName, options[propName],
                             constructor: true, silent: true)
            super
            @initialized = true
            for propName in bindablePropertyNames
                @onPropertyInitialBind(propName)

        initialize: (options={}) ->
            super
            for propName in @getBindablePropertyNames()
                @setProperty(propName, options[propName],
                             initialize: true, silent: true)

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


        ###Set a number of attributes using options, default value and checks
        their presence.

        @param options Object to take values from
        @param specs Array of attribute names or lists of [name, defaultVal]
        @param requiredAttributes Array of required names to check or a boolean
            if all the values should be present (optional)

        Example:

            this.setOptions(
                options
                ['name', 'age', ['planet', 'earth'], 'superPower']
                ['name', 'age', 'planet']
            )

        ###
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

        #TODO: refactor this using PropertySetupPrototype

        ###Sets an attribute.

        @param options Object to take the value from
        @param name
        @param defaultVal optional
        @param isRequired optional
        @param optName optional
        @param normalizer optional

        Example:

            this.setOption(options, 'name', 'Stefan')
            this.setOption(options, 'age', null, true)

        ###
        setOption: (options, name, defaultVal, isRequired=false, optName,
                    normalizer) ->
            optName ?= name
            normalizer ?= _.identity
            @[name] = normalizer(options[optName]) if options[optName]?
            @[name] ?= defaultVal if defaultVal?
            if isRequired and not @[name]?
                console.error("Missing required attribute: #{name}")

        ###
        For consistency, this should return DOM node. Currently both DOM and
        jQuery object are supported.
        ###
        getContainerEl: ->
            _.result(@, 'containerEl') or (_.result(@, 'containerView') or _.result(@, 'parentView'))?.el

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


    ###
    BasePlantChildView is used by the ElementView and MediumBaseView.
    It assumes that the subclass defines properly the setCoreOpacity
    method.
    ###
    class PlantChildView extends BaseView

        ###
        this method should be overriden in subclasses of this class
        ###
        setCoreOpacity: (opacity) ->

        ###
        Maps the model
        ###
        getModelOpacity: ->
            marked = @model.get('marked')
            if marked in [true, false]
                opacity = markedOpacityMap[marked]
            else
                opacity = visibilityOpacityMap[@model.get('visibilityType')]
            opacity ?= 1.0
            opacity

        getOpacity: ->
            if @animOpacity?
                @animOpacity
            else
                @getModelOpacity()

        ###
        Apply the visibility from model on view element.
        ###
        updateVisibility: ->
            @setCoreOpacity(@getOpacity())

        ###
        This method is used to apply opacity during animation. the given
        opacity should be multiplied by the model opacity (implied from
        the model visibility) and then applied on the view DOM element using
        the setCoreOpacity method.
        ###
        setAnimOpacity: (opacity=1.0) ->
            @animOpacity = opacity
            @updateVisibility()


    class Label extends BaseView
        className: 'lg-label'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'text')

        renderCore: ->
            @$el.text(@text)


    module.exports =
        BaseView: BaseView
        PlantChildView: PlantChildView
        Label: Label
