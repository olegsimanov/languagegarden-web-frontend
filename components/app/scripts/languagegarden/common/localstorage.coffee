    'use strict'

    _ = require('underscore')


    class LocalStorage

        @getInstance: =>
            @factoryRunningFlag = true
            @_instance ?= new this()
            @factoryRunningFlag = false
            @_instance

        constructor: ->
            if not @constructor.factoryRunningFlag
                throw "please use the getInstance factory class method"

            @storage = window.localStorage
            @enabled = @testSupport()

        testSupport: ->
            try
                testKey = '__lglocalstorage__'
                @set(testKey, testKey)
                enabled = @get(testKey) == testKey
                @remove(testKey)
            catch
                enabled = false

            enabled

        serialize: (value) -> JSON.stringify(value)

        deserialize: (value) ->
            if not _.isString(value)
                undefined
            try
                JSON.parse(value)
            catch
                value

        set: (key, val) ->
            if not val?
                return @remove(key)
            @storage.setItem(key, @serialize(val))
            val

        get: (key) => @deserialize(@storage.getItem(key))

        remove: (key) => @storage.removeItem(key)

        clear: => @storage.clear()

        log: => console.log(@storage)

    module.exports =
        LocalStorage: LocalStorage
