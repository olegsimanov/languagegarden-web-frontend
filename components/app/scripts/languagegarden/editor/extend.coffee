    'use strict'

    _ = require('underscore')


    extendHelper = (parent, protoProps, staticProps) ->

        if protoProps && _.has(protoProps, 'constructor')
            child = protoProps.constructor
        else
            child = (args...)-> parent.apply(this, args)

        _.extend(child, parent, staticProps)

        Surrogate = ->
            @constructor = child
            return this
        Surrogate.prototype = parent.prototype
        child.prototype     = new Surrogate()

        if protoProps
            _.extend(child.prototype, protoProps)

        child.__super__ = parent.prototype
        child


    extend = (protoProps, staticProps) -> extendHelper(this, protoProps, staticProps)


    module.exports =
        extend:     extend
