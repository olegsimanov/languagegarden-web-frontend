    'use strict'

    _ = require('underscore')
    {
        EditorToolbarView,
        EditorSubToolbarView
    }                           = require('./base')
    {SquarePickerView}          = require('./../colorpicker/square')
    {SelectionButtonGroupView}  = require('./../buttongroups/selection')
    {StatefulToolbarView}       = require('./../../views/toolbars/stateful')
    {NavButtonView}             = require('./../../views/toolbars/navbuttons')
    {
        SaveAndGoToNavigatorAction
        DiscardAndGoToNavigatorAction
    }                           = require('./../../actions/navigation')
    {CanvasMode}                = require('./../../constants')
    settings                    = require('./../../../settings')

    ToolbarEnum =
        NAVIGATION:     'navigation'
        BUILDER:        'builder'
        COLOR:          'color'

    class PaletteNavButtonView extends NavButtonView

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


    class TooltipToolbarView extends EditorToolbarView

        toolbarName: ToolbarEnum.BUILDER

        plantNavMenu: [
            actionClass:    DiscardAndGoToNavigatorAction
            viewType:       'button'
            context:        {customClassName: 'icon icon_back'}
        ]
        contentMenu: [
            viewClass: SelectionButtonGroupView,
            viewType: 'buttongroup'
        ]
        controlButtonsMenu: [

            viewClass:      PaletteNavButtonView
            viewType:       'navbutton'
            context:        {navTarget: ToolbarEnum.COLOR}
        ,
            actionClass:    SaveAndGoToNavigatorAction
            viewType:       'button'
            context:        {customClassName: 'icon icon_check'}

        ]

    class ColorToolbarView extends EditorSubToolbarView

        toolbarName: ToolbarEnum.COLOR

        rightSide: [{viewClass: SquarePickerView, viewType: 'palette'}]

        onActiveChanged: ->
            canvasView  = @controller.canvasView
            mode        = if @active then CanvasMode.COLOR else canvasView.getDefaultMode()
            canvasView.setMode(mode)


    class BuilderToolbarView extends StatefulToolbarView

        defaultState: TooltipToolbarView::toolbarName

        toolbarClasses: [
            TooltipToolbarView
            ColorToolbarView
        ]

        stateFromTargetName: (targetName) =>
            if targetName == 'back'
                @defaultState
            else
                targetName


    module.exports =
        BuilderToolbarView:     BuilderToolbarView
        TooltipToolbarView:     TooltipToolbarView
        ColorToolbarView:       ColorToolbarView
