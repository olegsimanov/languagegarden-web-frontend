    'use strict'

    _                               = require('underscore')
    Backbone                        = require('backbone')

    {extend}                        = require('./extend')
    {ICanMakePropertyFromOptions}    = require('./properties')


    ICanForwardEvents =

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

    class ICanExtend                                 # we need this intermediary class with 'extend' method because
        @extend:    extend                                  # Backbone.Events class doesn't have 'extend' method which will be used below

    EventsAwareBaseObject = ICanExtend
        .extend(Backbone.Events)
        .extend(ICanForwardEvents)
        .extend(ICanMakePropertyFromOptions)

    class EventsAwareClass extends EventsAwareBaseObject

        remove: -> @stopListening()                        # this is Backbone.Events method


    module.exports =
        EventsAwareClass:       EventsAwareClass
        ICanForwardEvents:      ICanForwardEvents
