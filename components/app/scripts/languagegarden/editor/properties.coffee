    'use strict'

    _ = require('underscore')

    ICanMakePropertyFromOptions =

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
        ICanMakePropertyFromOptions:     ICanMakePropertyFromOptions
