    'use strict'

    _ = require('underscore')


    StatefulClassPrototype =

        # cycling through states
        getCurrentStateIndex: -> _.indexOf(@states, @currentState)
        getNextStateIndex: -> (@getCurrentStateIndex() + 1) % @states.length
        getPrevStateIndex: ->
            # TODO: use %% operator after upgrade to Coffeescript 1.7 ?
            (@getCurrentStateIndex() + @states.length - 1) % @states.length
        getNextState: -> @states[@getNextStateIndex()]
        getPrevState: -> @states[@getPrevStateIndex()]

        getState: -> @currentState
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
