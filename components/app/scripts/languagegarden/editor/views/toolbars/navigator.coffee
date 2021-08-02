    'use strict'

    _ = require('underscore')
    {StatefulToolbar} = require('./../../../common/views/toolbars/stateful')
    {EditorSubToolbar, EditorToolbar} = require('./base')
    buttons = require('./../buttons')
    settings = require('./../../../settings')
    {ToolbarEnum} = require('./../../../common/views/toolbars/constants')
    {ActivityEditionToolbar} = require('./activities')
    {GoToStationCreator} = require('./../../actions/navigation')
    {DuplicateStationDropDown} = require('./../dropdowns')


    ###Main navigation toolbar###
    class NavigationSubToolbar extends EditorToolbar

        toolbarName: ToolbarEnum.NAVIGATION

        plantNavMenu: []
        contentMenu: [
            {
                viewClass: buttons.GoToStationEditorButton
                viewType: 'button'
                context:
                    templateString: '
                        <div class="icon icon_wrench"></div>
                        <div class="button__caption">
                            Edit <br />
                            <b>Station</b>
                        </div>'
            }
            {
                viewClass: buttons.DeleteLastStationButton,
                viewType: 'button'
                context:
                    templateString: '
                        <div class="icon icon_compass"></div>
                        <div class="button__caption">
                            Delete <br />
                            <b>Station</b>
                        </div>'
            }
        ]
        controlButtonsMenu: [
            {viewClass: buttons.GoToPlantsListButton, viewType: 'button'}
        ]


    class StationCreationToolbar extends EditorSubToolbar
        toolbarName: ToolbarEnum.STATION_CREATION

        contentMenu: [
            actionClass: GoToStationCreator
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_light-bulb"></div>
                    <div class="button__caption">
                        Create new<br />
                        <b>Station</b>
                    </div>'
        ,
            viewClass: DuplicateStationDropDown
            viewType: 'button'
        ]


    class TitlePageToolbar extends EditorToolbar
        toolbarName: ToolbarEnum.TITLE_PAGE


    class NavigationToolbar extends StatefulToolbar

        defaultState: NavigationSubToolbar::toolbarName

        toolbarClasses: [
            TitlePageToolbar
            NavigationSubToolbar
            ActivityEditionToolbar
            StationCreationToolbar
        ]

        initialize: ->
            super
            sidebarState = @controller.sidebarTimeline.getSidebarState()
            @listenTo(sidebarState, 'change:activeChapterIndex',
                @onActiveChapterIndexChange
            )

        onActiveChapterIndexChange: (model, value) ->
            if value == 0
                @setActiveView(TitlePageToolbar::toolbarName)
            else
                @setActiveView(@defaultState)

        stateFromTargetName: (targetName) =>
            if targetName == 'back'
                @defaultState
            else
                targetName

    module.exports =
        NavigationToolbar: NavigationToolbar
