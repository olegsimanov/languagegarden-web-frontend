    'use strict'

    _ = require('underscore')
    {RenderableView} = require('./../renderable')
    {StatefulClassPrototype} = require('./../../../common/stateful')
    {BaseToolbar} = require('./base')


    StatefulRenderableView = RenderableView
        .extend(StatefulClassPrototype)

    ###Toolbar that renders different toolbar depending on its state.###
    class StatefulToolbarBase extends StatefulRenderableView

        # Map of label to children class {stateName: toolbarClass}
        toolbars: undefined
        getToolbars: => @toolbars
        getToolbarForName: (toolbarName) => @toolbars[toolbarName]

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

        stateFromTargetName: (targetName) => targetName

        onToolbarNavEvent: (sender, targetName) ->
            @setState(@stateFromTargetName(targetName))

        onStateChange: (sender, state) => @setActiveView(state)

        setActiveView: (state=@currentState) =>
            for own toolbarName, toolbarView of @toolbarViews
                if toolbarName != state
                    toolbarView.setActive(false)
            @toolbarViews[state].setActive(true)

    ###Provides easier child specification as a list of classes which is
    converted into map of form: {name: view}
    ###
    class StatefulToolbar extends StatefulToolbarBase

        defaultState: null
        toolbarClasses: null

        initialize: (options) =>
            @toolbars = _.object(_.map(
                @toolbarClasses, (tbc) -> [tbc::toolbarName, tbc]
            ))
            @states = _.keys(@toolbars)
            super
            @subviews = {'': _.values(@toolbarViews)}


    module.exports =
        BaseToolbar: BaseToolbar
        StatefulToolbar: StatefulToolbar
