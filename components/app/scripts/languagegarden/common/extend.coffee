    'use strict'

    _ = require('underscore')


    # the extend from http://backbonejs.org/docs/backbone.html
    # on steroids + parent argument
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
        child.prototype = new Surrogate()

        if protoProps
            _.extend(child.prototype, protoProps)

            if _.has(protoProps, '__required_interface_methods__')
                for methodName in protoProps.__required_interface_methods__
                    if not child.prototype[methodName]?
                        do ->
                            msg = "called missing #{methodName} method!"
                            child.prototype[methodName] = ->
                                console.error(msg)


        child.__super__ = parent.prototype
        child


    extend = (protoProps, staticProps) ->
        extendHelper(this, protoProps, staticProps)


    extendAll = (protoPropsList...) ->
        child = this
        for protoProps in protoPropsList
            child = extendHelper(child, protoProps)
        child


    module.exports =
        extend: extend
        extendAll: extendAll
