    'use strict'

    _ = require('underscore')
    settings = require('./../../settings')
    {disableSelection} = require('./../../common/domutils')
    historyActions = require('./../actions/history')
    mediaActions = require('./../actions/media')
    {Point} = require('./../../math/points')
    {BaseView} = require('./../../common/views/base')
    {EditorMode, ColorMode} = require('./../constants')
    {
        DivButton
        DivToggleButton
        TooltipButton
    } = require('./../../common/views/buttons')
    navigationActions = require('./../actions/navigation')
    activityActions = require('./../actions/activities')
    stationsActions = require('./../actions/stations')


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


    class TimelineActionButton extends MenuActionButton

        initialize: (options) ->
            super
            model = @getEditor().model
            @listenTo(model, 'diffpositionchange', @onChange)
            @listenTo(model.changes, 'change', @onChange)

        remove: ->
            model = @getEditor().model
            @stopListening(model.changes)
            super


    class BaseSelectedActivityButton extends MenuActionButton

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'sidebarTimeline',
                                    default: @controller.sidebarTimeline
                                    required: true)
            @listenTo(@sidebarTimeline.getSidebarState(), 'all',
                      @onChange)

        remove: ->
            @stopListening(@sidebarTimeline.getSidebarState())
            super


    class AddMediaButton extends MenuActionButton

        onClick: =>
            dataModel = @controller.dataModel
            insertPoint = new Point(dataModel.get('canvasWidth') / 2,
                                    dataModel.get('canvasHeight') / 2)
            @action.setPoint(insertPoint)
            super


    class AddOrEditMediaButton extends MenuActionButton

        mediaChosenClass: 'active'

        initialize: (options) ->
            super
            @listenTo(@model.media, 'add remove change reset', @render)

        isMediumChosen: -> @action.getMediumToEdit()?

        render: ->
            super
            @$el.toggleClass(@mediaChosenClass, @isMediumChosen())
            this


    class OpenModalButton extends MenuButton

        initialize: (options) =>
            super
            @modalView ?= options.modalView

        isEnabled: -> true

        onClick: (event) =>
            if not @isEnabled()
                return true
            @modalView.show()


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


    class SettingsButton extends OpenModalButton
        customClassName: 'icon icon_cogwheel'


    # media buttons
    class AddImageButton extends AddMediaButton
        actionClass: mediaActions.AddImage
        customClassName: 'icon icon_image'


    class AddSoundButton extends AddMediaButton
        actionClass: mediaActions.AddSound


    class AddPlantLinkButton extends AddMediaButton
        actionClass: mediaActions.AddPlantLink


    class AddTextButton extends AddMediaButton
        actionClass: mediaActions.AddText
        customClassName: 'add-text-button'


    class AddNoteButton extends AddMediaButton
        actionClass: mediaActions.AddNote
        customClassName: 'add-note-button'
        customClassName: 'icon icon_note'


    class AddTextToPlantNoteButton extends AddMediaButton
        actionClass: mediaActions.AddTextToPlantNote
        customClassName: 'add-text-to-plant-note-button'


    class AddPlantToTextNoteButton extends AddMediaButton
        actionClass: mediaActions.AddPlantToTextNote
        customClassName: 'add-plant-to-text-note-button'


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


    class RemoveSelectedActivityButton extends BaseSelectedActivityButton
        actionClass: activityActions.RemoveSelectedActivity


    class MoveSelectedActivityUpButton extends BaseSelectedActivityButton
        actionClass: activityActions.MoveSelectedActivityUp


    class MoveSelectedActivityDownButton extends BaseSelectedActivityButton
        actionClass: activityActions.MoveSelectedActivityDown


    class GoToSelectedActivityFromNavigatorButton extends BaseSelectedActivityButton
        actionClass: activityActions.GoToSelectedActivityFromNavigator


    class DeleteLastStationButton extends MenuActionButton
        actionClass: stationsActions.DeleteLastStation
        modelListenEventName: 'diffpositionchange'

        isHidden: -> not @isEnabled()

        help: -> 'Delete current station'


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
        SettingsButton: SettingsButton
        AddTextButton: AddTextButton
        AddImageButton: AddImageButton
        AddSoundButton: AddSoundButton
        AddPlantLinkButton: AddPlantLinkButton
        AddNoteButton: AddNoteButton
        AddTextToPlantNoteButton: AddTextToPlantNoteButton
        AddPlantToTextNoteButton: AddPlantToTextNoteButton
        GoToStationEditorButton: GoToStationEditorButton
        RemoveSelectedActivityButton: RemoveSelectedActivityButton
        MoveSelectedActivityUpButton: MoveSelectedActivityUpButton
        MoveSelectedActivityDownButton: MoveSelectedActivityDownButton
        GoToSelectedActivityFromNavigatorButton: GoToSelectedActivityFromNavigatorButton
        DeleteLastStationButton: DeleteLastStationButton
