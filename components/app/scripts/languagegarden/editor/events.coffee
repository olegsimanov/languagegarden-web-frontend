    'use strict'

    _                           = require('underscore')
    Backbone                    = require('backbone')
    {extend, extendAll}         = require('./extend')
    {PropertySetupPrototype}    = require('./properties')


    EventForwardingPrototype =

        setupEventForwarding: (target, eventNames, retainSource=true) ->
            if not _.isArray(eventNames)
                eventNames = [eventNames]
            for eventName in eventNames
                do =>
                    evName = eventName
                    if retainSource
                        handler = (args...) -> @trigger(evName, args...)
                    else
                        handler = (src, args...) ->
                            @trigger(evName, this, args...)

                    @listenTo(target, evName, handler)


    class CoreEventObject
        @extend:    extend
        @extendAll: extendAll


    BaseEventObject = CoreEventObject.extendAll(Backbone.Events, EventForwardingPrototype, PropertySetupPrototype)


    class EventObject extends BaseEventObject

#        constructor: (options) ->
#            @initialize(options)
#
#        initialize: (options) ->

        remove: ->
            @stopListening()                        # this is Backbone.Events method
            @removed = true


    module.exports =
        EventObject: EventObject
        EventForwardingPrototype: EventForwardingPrototype
