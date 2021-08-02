    'use strict'

    _ = require('underscore')
    settings = require('./../../../settings')
    {template} = require('./../../../common/templates')
    {Label} = require('./../../../common/views/base')
    {BaseToolbar} = require('./../../../common/views/toolbars/base')
    {StatefulToolbar} = require('./../../../common/views/toolbars/stateful')
    {PlayHiddenSoundButton, NextActivityButton} = require('./../buttons')
    {
        RetryActiveActivity
        SubmitAnswer
    } = require('./../../actions/active_activities')
    {
        StartPlantToTextMemoTest
        RetryPlantToTextMemoStart
    } = require('./../../actions/plant_to_text')
    {PlantToTextButtonGroup} = require('./../buttongroups/plant_to_text')
    {HiddenSoundProgressBar} = require('./../progress/bars')


    #
    # PLANT PLAYER
    #
    class PlayerToolbar extends BaseToolbar

        template: template('./common/toolbars/container.ejs')

        toolbarViewAnchors:
            '.toolbar__section_left': 'plantPreviousStationMenu'
            '.toolbar__section_mid': 'controlButtonsMenu'
            '.toolbar__section_right': 'plantNextStationMenu'

        controlButtonsMenu: []
        plantPreviousStationMenu: []
        plantNextStationMenu: []


    class PlantPlayerToolbar extends PlayerToolbar

        controlButtonsMenu: []
        plantNextStationMenu: []

    #
    # ACTIVITIES
    #
    class PlayerActivityToolbar extends PlayerToolbar
        plantPreviousStationMenu: [
            viewClass: PlayHiddenSoundButton
            viewType: 'timelineButton'
            getContext: (toolbar) ->
                toolbarView: toolbar
        ,
            viewClass: HiddenSoundProgressBar
            viewType: 'viewWithTimeline'
        ]

        plantNextStationMenu: [
            viewClass: NextActivityButton
            viewType: 'button'
        ]

        onActiveChanged: ->
            @trigger('activeChanged', this)


    class MediaActivityPlayerToolbar extends PlayerActivityToolbar


    class P2TActivityPlayerToolbar extends PlayerActivityToolbar


    class ActiveActivityStartPlayerToolbar extends PlayerActivityToolbar
        toolbarName: 'start'

        plantNextStationMenu: [
            actionClass: SubmitAnswer
            viewType: 'button'
            context:
                templateString: '<div class="icon icon_check"></div>'
        ]


    class NoOpPlayerToolbar extends PlayerToolbar
        toolbarName: 'no-op'
        plantNextStationMenu: []


    class AnswerOkPlayerToolbar extends PlayerActivityToolbar
        toolbarName: 'answer-ok'

        plantPreviousStationMenu: null

        controlButtonsMenu: [
            viewClass: Label
            viewType: 'label'
            context:
                className: 'activity-progress-label activity-progress-label_green'
                text: 'Well Done'
        ]


    class AnswerInvalidPlayerToolbar extends PlayerToolbar
        toolbarName: 'answer-invalid'

        controlButtonsMenu: [
            viewClass: Label
            viewType: 'label'
            context:
                className: 'activity-progress-label activity-progress-label_red'
                text: 'Try Again'
        ]

        plantNextStationMenu: [
            actionClass: RetryActiveActivity
            viewType: 'button'
            context:
                templateString: '<div class="icon icon_back"></div>'
        ]


    class ActiveActivityPlayerToolbar extends StatefulToolbar
        @startToolbarClass: ActiveActivityStartPlayerToolbar
        defaultState: @startToolbarClass::toolbarName
        toolbarClasses: [
            @startToolbarClass
            NoOpPlayerToolbar
            AnswerOkPlayerToolbar
            AnswerInvalidPlayerToolbar
        ]

        stateFromTargetName: (targetName) ->
            if targetName == 'retry'
                @defaultState
            else
                targetName


    class ActiveP2TActivityStartPlayerToolbar extends ActiveActivityStartPlayerToolbar
        plantNextStationMenu: [
            viewClass: PlantToTextButtonGroup
            viewType: 'buttongroup'
        ].concat(ActiveActivityStartPlayerToolbar::plantNextStationMenu)


    class ActiveP2TActivityPlayerToolbar extends ActiveActivityPlayerToolbar
        @startToolbarClass: ActiveP2TActivityStartPlayerToolbar
        defaultState: @startToolbarClass::toolbarName
        toolbarClasses: [
            @startToolbarClass
        ].concat(ActiveActivityPlayerToolbar::toolbarClasses.slice(1))

        #TODO: remove?
        stateFromTargetName: (targetName) ->
            if targetName == 'retry'
                @defaultState
            else
                targetName


    class ActiveP2TMemoActivityStartPlayerToolbar extends PlayerActivityToolbar
        toolbarName: 'start'
        plantNextStationMenu: [
            actionClass: StartPlantToTextMemoTest
            viewType: 'button'
            context:
                templateString: '
                <div class="icon icon_bold-arrow-right"></div>'
        ]


    class ActiveP2TMemoActivityTestPlayerToolbar extends ActiveActivityStartPlayerToolbar
        toolbarName: 'pt2-memo-test'
        plantPreviousStationMenu: [
            actionClass: RetryPlantToTextMemoStart
            viewType: 'button'
            context:
                templateString: '
                <div class="icon icon_bold-arrow-left"></div>'
        ]
        plantNextStationMenu: [
            viewClass: PlantToTextButtonGroup
            viewType: 'buttongroup'
        ].concat(ActiveActivityStartPlayerToolbar::plantNextStationMenu)


    class ActiveP2TMemoActivityPlayerToolbar extends ActiveActivityPlayerToolbar
        @startToolbarClass: ActiveP2TMemoActivityStartPlayerToolbar
        defaultState: @startToolbarClass::toolbarName
        toolbarClasses: [
            @startToolbarClass
            ActiveP2TMemoActivityTestPlayerToolbar
        ].concat(ActiveActivityPlayerToolbar::toolbarClasses.slice(1))


    module.exports =
        PlantPlayerToolbar: PlantPlayerToolbar
        GenericActivityPlayerToolbar: PlayerActivityToolbar
        MediaActivityPlayerToolbar: MediaActivityPlayerToolbar
        P2TActivityPlayerToolbar: P2TActivityPlayerToolbar
        ActiveActivityPlayerToolbar: ActiveActivityPlayerToolbar
        ActiveP2TActivityPlayerToolbar: ActiveP2TActivityPlayerToolbar
        ActiveP2TMemoActivityPlayerToolbar: ActiveP2TMemoActivityPlayerToolbar
