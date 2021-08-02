    'use strict'

    _ = require('underscore')
    {template} = require('./../../../common/templates')
    {BaseToolbar} = require('./../../../common/views/toolbars/base')
    {ToolbarBackButton} = require('./../../../common/views/toolbars/navbuttons')


    class EditorToolbar extends BaseToolbar

        template: template('./common/toolbars/navigator.ejs')

        toolbarViewAnchors:
            '.station-navigator': 'plantNavMenu'
            '.toolbar__section_mid': 'contentMenu'
            '.toolbar__section_right': 'controlButtonsMenu'

        desktopInit: ->
            if @controller.getShowSettings()
                {SettingsMenu} = require('../settings')
                @settingsView = new SettingsMenu
                    controller: @controller
                    canvasView: @controller.canvasView
                    model: @controller.model
                    dataModel: @controller.dataModel
                    timeline: @controller.timeline

        remove: ->
            @removeSubview('settingsView')
            super


    class EditorSubToolbar extends EditorToolbar

        template: template('./common/toolbars/container.ejs')

        backNav: [
            {viewClass: ToolbarBackButton, viewType: 'navbutton'}
        ]

        toolbarViewAnchors:
            '.toolbar__section_left': 'backNav'
            '.toolbar__section_mid': 'contentMenu'
            '.toolbar__section_right': 'rightSide'


    module.exports =
        EditorToolbar: EditorToolbar
        EditorSubToolbar: EditorSubToolbar
