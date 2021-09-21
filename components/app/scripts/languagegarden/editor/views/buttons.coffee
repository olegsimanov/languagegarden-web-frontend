    'use strict'

    _ = require('underscore')
    settings = require('./../../settings')
    {Point} = require('./../../math/points')
    {BaseView} = require('./../../common/views/base')
    {EditorMode, ColorMode} = require('./../constants')
    {
        DivButton
        DivToggleButton
        TooltipButton
    } = require('./../../common/views/buttons')
    navigationActions = require('./../actions/navigation')


    class EditorDivButton extends DivButton

        initialize: (options) ->
            # pass model from options.controller so BaseView can use set it
            if options?
                options.model ?= options?.controller?.model
            # TODO: this limits any inheriting view to append directly to the
            # editor or break the getEditor reference.
            options.parentView = options.editor if options?.editor?
            super(options)
            # the this.editor field is deprecated. please use this.getEditor()
            # instead.
            @editor = @parentView

        getEditor: -> @parentView


    class EditorDivToggleButton extends DivToggleButton

        initialize: (options) ->
            options.parentView = options.editor if options?.editor?
            super

        getEditor: -> @parentView


    class MenuButton extends EditorDivButton


    class MenuActionButton extends MenuButton
        modelListenEventName: 'editablechange'

        initialize: (options) =>
            super
            @disabled = not @isEnabled()
            @hidden = @isHidden()
            if options.modelListenEventName?
                @modelListenEventName = options.modelListenEventName
            @listenTo(@parentView.model, @modelListenEventName, @onChange)

        remove: ->
            @stopListening(@parentView.model)
            super

        getActionOptions: (options) ->
            controller: options.controller
            parentView: @parentView

        isEnabled: -> @action.isAvailable()

        isToggled: -> @action.isToggled()

        isHidden: -> false

        onChange: =>
            @disabled = not @isEnabled()
            @hidden = @isHidden()
            @$el.toggleClass('toggled', @isToggled())
            @render()

        onClick: (event) =>
            if not @isEnabled()
                return true
            event.preventDefault()
            @action.fullPerform()

    # mode buttons
    class EditorColorModeButton extends EditorDivToggleButton

        className: "color-mode-button #{EditorDivToggleButton::className}"

        states: [ColorMode.WORD, ColorMode.LETTER]
        defaultState: ColorMode.DEFAULT

        initialize: (options) =>
            super
            @model = options.model
            @editor = options.editor
            @setState(@model.get('colorMode'))
            @listenTo(@model, 'change:colorMode', @onColorModeChange)

        onColorModeChange: (sender, value) => @setState(value)

        remove: =>
            @stopListening(@model)
            delete @model
            delete @editor
            super

        render: =>
            super

        onClick: =>
            super
            @model.set('colorMode', @currentState)

    # navigation buttons

    class GoToPlantsListButton extends MenuActionButton
        actionClass: navigationActions.GoToPlantsList
        customClassName: 'icon icon_home'


    class DoneButton extends MenuActionButton
        actionClass: navigationActions.SaveAndGoToNavigator
        customClassName: 'icon icon_check'


    class GoToEditorActionButton extends MenuActionButton
        modelListenEventName: 'diffpositionchange'
        isHidden: -> not @isEnabled()


    class GoToStationEditorButton extends GoToEditorActionButton
        actionClass: navigationActions.GoToStationEditor

    module.exports =
        ImageButton: EditorDivButton
        TooltipButton: TooltipButton
        MenuActionButton: MenuActionButton
        #deprecated, do not use
        GoToPlantsListButton: GoToPlantsListButton
        DoneButton: DoneButton
        DivButton: EditorDivButton
        EditorDivButton: EditorDivButton
        EditorDivToggleButton: EditorDivToggleButton
        EditorColorModeButton: EditorColorModeButton
        GoToStationEditorButton: GoToStationEditorButton
