    'use strict'

    _ = require('underscore')
    {capitalize} = require('./utils')


    buildPropertySupportPrototype = (propName) ->
        setterName = "set#{capitalize(propName)}"
        bindHandlerName = "on#{capitalize(propName)}Bind"
        unbindHandlerName = "on#{capitalize(propName)}Unbind"
        proto = {}
        proto[setterName] = (value, options={}) ->
            silent = options.silent or false
            force = options.force or false

            if value == @[propName] and not force
                return this
            if @[propName]? and not silent
                @[unbindHandlerName](options)
            @[propName] = value
            if @[propName]? and not silent
                @[bindHandlerName](options)
            this

        proto[bindHandlerName] = ->
        proto[unbindHandlerName] = -> @stopListening(@[propName])
        proto


    PropertySetupPrototype =

        ###Sets an object property using the input options, usually passed to
        the constructor or initialize method.

        @param inputOptions Object to take the value from
        @param propName Name of the property
        @param options Dictionary of optional settings like:
            default, required, normalizer, optionName

        Example:

            this.setPropertyFromOptions(options, 'name', default: 'Stefan')
            this.setPropertyFromOptions(options, 'age', required: true)

        ###
        setPropertyFromOptions: (inputOptions, propName, options={})->
            unsupportedOptions = _.difference(_.keys(options), [
                'defaultValue', 'default', 'optionName', 'normalizer', 'required'])
            if unsupportedOptions.length > 0
                console.warn("setPropertyFromOptions: setting #{propName} with " +
                             "unsupported options " +
                             "#{unsupportedOptions.join(', ')}")
            optName = options.optionName or propName
            defaultValue = options.defaultValue
            # the options.defaultValue may be 0, so we can't use 'or idiom' here
            defaultValue ?= options.default
            normalizer = options.normalizer or _.identity
            required = options.required
            required ?= false

            if inputOptions[optName]?
                @[propName] = normalizer(inputOptions[optName])
            else if defaultValue?
                @[propName] ?= defaultValue

            if required and not @[propName]?
                console.error("Missing required attribute: #{propName}")
            this

        setPropertiesFromOptions: (inputOptions, propNames, options={}) ->
            for propName in propNames
                @setPropertyFromOptions(inputOptions, propName, options)
            this


    module.exports =
        buildPropertySupportPrototype: buildPropertySupportPrototype
        PropertySetupPrototype: PropertySetupPrototype
