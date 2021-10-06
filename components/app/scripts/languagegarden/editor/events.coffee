    'use strict'

    _                               = require('underscore')

    Backbone                        = require('backbone')
    {extend, extendAll}             = require('./extend')
    {CanMakePropertyFromOptions}    = require('./properties')


    CanForwardEvents =

        forwardEventsFrom: (target, eventNames, retainSource=true) ->
            if not _.isArray(eventNames)
                eventNames = [eventNames]
            for eventName in eventNames
                do =>
                    evName = eventName
                    if retainSource
                        handler = (args...) -> @trigger(evName, args...)
                    else
                        handler = (src, args...) -> @trigger(evName, this, args...)

                    @listenTo(target, evName, handler)

    class WithExtendMethods

        @extend:    extend
        @extendAll: extendAll

    EventsAwareBaseObject = WithExtendMethods
        .extend(Backbone.Events)
        .extend(CanForwardEvents)
        .extend(CanMakePropertyFromOptions)

    class EventsAwareClass extends EventsAwareBaseObject

        remove: -> @stopListening()                        # this is Backbone.Events method


    module.exports =
        EventsAwareClass:   EventsAwareClass
        CanForwardEvents:   CanForwardEvents
