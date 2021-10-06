    'use strict'

    _ = require('underscore')

    {capitalize} = require('./utils')


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


    CanMakePropertyFromOptions =

        setPropertyFromOptions: (inputOptions, propName, options= {})    ->

            unsupportedOptions = _.difference(_.keys(options), ['defaultValue', 'default', 'optionName', 'normalizer', 'required'])

            if unsupportedOptions.length > 0
                console.warn("setPropertyFromOptions: setting #{propName} with unsupported options #{unsupportedOptions.join(', ')}")

            optName         = options.optionName or propName
            defaultValue    = options.defaultValue
            defaultValue    ?= options.default
            normalizer      = options.normalizer or _.identity
            required        = options.required
            required        ?= false

            if inputOptions[optName]?
                @[propName] = normalizer(inputOptions[optName])
            else if defaultValue?
                @[propName] ?= defaultValue

            if required and not @[propName]?
                console.error("Missing required attribute: #{propName}")
            this

    module.exports =
        buildMixinWithProperty:         buildMixinWithProperty
        CanMakePropertyFromOptions:     CanMakePropertyFromOptions
