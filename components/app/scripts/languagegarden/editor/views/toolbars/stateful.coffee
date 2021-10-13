    'use strict'

    _ = require('underscore')
    {RenderableView}            = require('./../renderable')

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

    StatefulRenderableView = RenderableView.extend(StatefulClassPrototype)

    ###Toolbar that renders different toolbar depending on its state.###
    class StatefulToolbarBaseView extends StatefulRenderableView

        # Map of label to children class {stateName: toolbarClass}
        toolbars:       undefined
        getToolbars:    => @toolbars

        initialize: (options) =>
            super
            @setOptions(options, ['toolbars'], true)
            @setupStates(options)
            @toolbarViews = @createToolbarViews(options)
            @listenTo(@, 'change:state', @onStateChange)
            @setActiveView(@currentState)

        createToolbarViews: (options) =>
            toolbarViews = {}
            for own stateName, toolbarClass of @getToolbars()
                toolbarViews[stateName] = tv = new toolbarClass(
                    @getToolbarOptions(options)
                )
                for eventName in tv.forwardedToolbarNavEvents or []
                    @listenTo(tv, eventName, @onToolbarNavEvent)
            toolbarViews

        getToolbarOptions: (options) =>
            _.extend({
                controller: @controller
            }, options.toolbarOptions or {})

        remove: =>
            delete @controller
            @removeAllSubviews()
            @stopListening(@)
            super

        stateFromTargetName: (targetName)       => targetName
        onToolbarNavEvent: (sender, targetName) -> @setState(@stateFromTargetName(targetName))
        onStateChange: (sender, state)          => @setActiveView(state)

        setActiveView: (state=@currentState) =>
            for own toolbarName, toolbarView of @toolbarViews
                if toolbarName != state
                    toolbarView.setActive(false)
            @toolbarViews[state].setActive(true)


    class StatefulToolbarView extends StatefulToolbarBaseView

        defaultState:   null
        toolbarClasses: null

        initialize: (options) =>
            @toolbars = _.object(_.map(
                @toolbarClasses, (tbc) -> [tbc::toolbarName, tbc]
            ))
            @states = _.keys(@toolbars)
            super
            @subviews = {'': _.values(@toolbarViews)}


    module.exports =
        StatefulClassPrototype: StatefulClassPrototype
        StatefulToolbarView:    StatefulToolbarView
