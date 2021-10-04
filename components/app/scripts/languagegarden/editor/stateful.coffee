    'use strict'

    _ = require('underscore')


    StatefulClassPrototype =

        getCurrentStateIndex:   -> _.indexOf(@states, @currentState)
        getNextStateIndex:      -> (@getCurrentStateIndex() + 1) % @states.length
        getNextState:           -> @states[@getNextStateIndex()]

        setState: (state, options={}) ->
            state = @defaultState if not _.contains(@states, state)

            if state != @currentState
                @currentState = state
                if options.silent
                    return
                @trigger('change', @)
                @trigger('change:state', @, state)

        setupStates: (stateOptions) ->
            setDefault = (name, val) => @[name] = val if not @[name]?
            setIfPresent = (name) =>
                @[name] = stateOptions[name] if stateOptions[name]?

            setIfPresent('states')
            setIfPresent('defaultState')
            setIfPresent('currentState')
            setIfPresent('initialState')

            # set defaults if missing
            setDefault('defaultState', @states[0])
            setDefault('initialState', @defaultState)
            setDefault('currentState', @initialState)


    module.exports =
        StatefulClassPrototype: StatefulClassPrototype
