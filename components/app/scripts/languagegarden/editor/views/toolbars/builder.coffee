    'use strict'

    _ = require('underscore')
    {
        EditorToolbar,
        EditorSubToolbar
    }                           = require('./base')
    {SquarePicker}              = require('./../colorpicker/square')
    {SelectionButtonGroup}      = require('./../buttongroups/selection')
    {ToolbarEnum}               = require('./../../views/toolbars/constants')
    {StatefulToolbar}           = require('./../../views/toolbars/stateful')
    {ToolbarNavButton}          = require('./../../views/toolbars/navbuttons')
    {
        SaveAndGoToNavigator
        DiscardAndGoToNavigator
    }                           = require('./../../actions/navigation')
    {EditorMode}                = require('./../../constants')
    settings                    = require('./../../../settings')

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


    class TooltipToolbar extends EditorToolbar

        toolbarName: ToolbarEnum.BUILDER

        plantNavMenu: [
            actionClass: DiscardAndGoToNavigator
            viewType: 'button'
            context:
                customClassName: 'icon icon_back'
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
        ColorToolbar:   ColorToolbar
