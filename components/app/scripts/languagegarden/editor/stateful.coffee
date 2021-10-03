    'use strict'

    _ = require('underscore')


    ###Inteface for stateful class.
    Requires:
        @states A list of states
    Uses:
        @initialState One of the values in @states, button will start in
        @defaultState One of the values in @states, fallback
        @currentState One of the values in @states, for tracking state

    Triggers events:
        change, change:state

    ###
    StatefulClassPrototype =

        # cycling through states
        getCurrentStateIndex: -> _.indexOf(@states, @currentState)
        getNextStateIndex: -> (@getCurrentStateIndex() + 1) % @states.length
        getPrevStateIndex: ->
            # TODO: use %% operator after upgrade to Coffeescript 1.7 ?
            (@getCurrentStateIndex() + @states.length - 1) % @states.length
        getNextState: -> @states[@getNextStateIndex()]
        getPrevState: -> @states[@getPrevStateIndex()]

        # state manipulation
        inState: (state) -> @getState() == state
        getState: -> @currentState
        setState: (state, options={}) ->
            state = @defaultState if not _.contains(@states, state)

            if state != @currentState
                @currentState = state
                if options.silent
                    return
                @trigger('change', @)
                @trigger('change:state', @, state)

        ###Initializes state-related attributes.###
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
