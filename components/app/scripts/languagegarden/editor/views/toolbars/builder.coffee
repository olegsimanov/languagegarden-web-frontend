    'use strict'

    _ = require('underscore')
    {ToolbarEnum} = require('./../../../common/views/toolbars/constants')
    {EditorToolbar, EditorSubToolbar} = require('./base')
    {SquarePicker} = require('./../colorpicker/square')
    {SelectionButtonGroup} = require('./../buttongroups/selection')
    {
        SettingsButton
        AddImageButton
        AddNoteButton
    } = require('./../buttons')

    {Undo, Redo} = require('./../../actions/history')
    {
        DiscardAndGoToNavigator
        SaveAndGoToNavigator
    } = require('./../../actions/navigation')

    settings = require('./../../../settings')
    {StatefulToolbar} = require('./../../../common/views/toolbars/stateful')
    {ToolbarNavButton} = require('./../../../common/views/toolbars/navbuttons')
    {EditorMode} = require('./../../constants')



    class PaletteToolbarNavButton extends ToolbarNavButton

        getNavButtonClass: -> "#{super} icon icon_palette"

        initialize: (options) ->
            super
            @setOptions(options, ['controller'], true)
            @listenTo(@controller.canvasView, 'selectchange', @onSelectChange)
            @hidden = @shouldHide()

        onSelectChange: ->
            @hidden = @shouldHide()
            @render()

        shouldHide: -> @controller.canvasView.getSelectedElements().length == 0

        remove: ->
            @stopListening(@controller.canvasView)
            delete @controller
            super


    #
    # PLANT BUILDER
    #
    class TooltipToolbar extends EditorToolbar

        toolbarName: ToolbarEnum.BUILDER

        plantNavMenu: [
            actionClass: DiscardAndGoToNavigator
            viewType: 'button'
            context:
                customClassName: 'icon icon_back'
        ,
            actionClass: Undo
            viewType: 'button'
            context:
                customClassName: 'icon icon_spin-left'
        ,
            actionClass: Redo
            viewType: 'button'
            context:
                customClassName: 'icon icon_spin-right'
        ,
            {
                viewClass: SettingsButton
                viewType: 'button'
                getContext: (p) -> {modalView: p.settingsView}
                show: (p) ->
                    not settings.isMobile and p.controller.getShowSettings()
            }
        ]
        contentMenu: [
            {viewClass: SelectionButtonGroup, viewType: 'buttongroup'}
        ]
        controlButtonsMenu: [
            {
                viewType: 'navbutton'
                viewClass: PaletteToolbarNavButton
                context:
                    navTarget: ToolbarEnum.COLOR
            }
            {viewClass: AddImageButton, viewType: 'button'}
            {viewClass: AddNoteButton, viewType: 'button'}
        ,
            actionClass: SaveAndGoToNavigator
            viewType: 'button'
            context:
                customClassName: 'icon icon_check'
        ]

    class ColorToolbar extends EditorSubToolbar

        toolbarName: ToolbarEnum.COLOR

        rightSide: [
            {viewClass: SquarePicker, viewType: 'palette'}
        ]

        onActiveChanged: ->
            canvasView = @controller.canvasView
            mode = if @active then EditorMode.COLOR else canvasView.getDefaultMode()
            canvasView.setMode(mode)


    class BuilderToolbar extends StatefulToolbar

        defaultState: TooltipToolbar::toolbarName

        toolbarClasses: [
            TooltipToolbar
            ColorToolbar
        ]

        stateFromTargetName: (targetName) =>
            if targetName == 'back'
                @defaultState
            else
                targetName


    module.exports =
        BuilderToolbar: BuilderToolbar
        TooltipToolbar: TooltipToolbar
        ColorToolbar: ColorToolbar
