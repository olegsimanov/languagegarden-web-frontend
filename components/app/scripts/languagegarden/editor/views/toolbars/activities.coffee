    'use strict'

    _ = require('underscore')
    {ToolbarEnum} = require('./../../../common/views/toolbars/constants')
    {EditorToolbar, EditorSubToolbar} = require('./base')
    {
        GoToActivitySetupMenu
        SetupPlantToTextActivity
        SetupPlantToTextMemoActivity
        SetupClickActivity
        FinalizeActivity
        SubmitActiveActivity
        SubmitPassiveActivity
        CancelActivity
    } = require('./../../actions/activities')
    {MarkAllElements} = require('./../../actions/mark')
    {AddOrEditHiddenSound} = require('./../../actions/media')
    buttons = require('./../buttons')
    {
        PlantToTextButtonGroup
        PlantToTextPunctuationButtonGroup
    } = require('./../buttongroups/plant_to_text')
    {TooltipToolbar, ColorToolbar, BuilderToolbar} = require('./builder')
    {ToolbarBackButton} = require('./../../../common/views/toolbars/navbuttons')
    {ToolbarNavButton} = require('./../../../common/views/toolbars/navbuttons')


    class NavigatorSubToolbar extends EditorSubToolbar

        # removing the back arrow
        backNav: []

    #
    # ACTIVITY EDITOR
    #
    class ActivityEditorToolbar extends EditorSubToolbar

        @cancelActionClass: CancelActivity
        @cancelTemplateString: '<div class="icon icon_cross"></div>'
        @okActionClass: FinalizeActivity
        @okTemplateString: '<div class="icon icon_bold-arrow-right"></div>'

        @getCancelButtonInfo: ->
            actionClass: @cancelActionClass
            viewType: 'button'
            context:
                templateString: @cancelTemplateString

        @getOKButtonInfo: (actionClass) ->
            actionClass ?= @okActionClass
            actionClass: actionClass
            viewType: 'button'
            context:
                templateString: @okTemplateString


        cancelNav: [
            @getCancelButtonInfo()
        ]
        okNav: [
            @getOKButtonInfo()
        ]

        toolbarViewAnchors:
            '.toolbar__section_left': 'cancelNav'
            '.toolbar__section_mid': 'contentMenu'
            '.toolbar__section_right': 'okNav'


    class PunctuationToolbarNavButton extends ToolbarNavButton

        templateString: '
            <div class="icon icon_punctuation">
                ?;:!
            </div>'


    class P2TActivityTooltipToolbar extends ActivityEditorToolbar

        toolbarName: ToolbarEnum.P2T_ACTIVITY_EDITOR

        contentMenu: [
            {viewClass: PlantToTextButtonGroup, viewType: 'buttongroup'}
            {
                viewType: 'navbutton'
                viewClass: PunctuationToolbarNavButton
                context:
                    navTarget: ToolbarEnum.P2T_ACTIVITY_PUNCTUATION_EDITOR
            }
        ]


    class P2TActivityPunctuationToolbar extends ActivityEditorToolbar

        toolbarName: ToolbarEnum.P2T_ACTIVITY_PUNCTUATION_EDITOR
        okNav: []
        cancelNav: [
            {viewClass: ToolbarBackButton, viewType: 'navbutton'}
        ]
        contentMenu: [
            {
                viewClass: PlantToTextPunctuationButtonGroup
                viewType: 'buttongroup'
            }
        ]


    class P2TActivityEditorToolbar extends BuilderToolbar

        defaultState: P2TActivityTooltipToolbar::toolbarName

        toolbarClasses: [
            P2TActivityTooltipToolbar
            P2TActivityPunctuationToolbar
        ]


    class ClickActivityTooltipToolbar extends ActivityEditorToolbar

        toolbarName: ToolbarEnum.CLICK_ACTIVITY_EDITOR

        contentMenu: [
            actionClass: MarkAllElements
            viewType: 'button'
            context:
                templateString: '<div class="icon icon_select-all"></div>'
        ]


    class ClickActivityEditorToolbar extends BuilderToolbar

        defaultState: ClickActivityTooltipToolbar::toolbarName

        toolbarClasses: [
            ClickActivityTooltipToolbar
        ]


    class DictionaryActivityTooltipToolbar extends TooltipToolbar

        toolbarName: ToolbarEnum.DICTIONARY_ACTIVITY_EDITOR

        plantNavMenu: [
            ActivityEditorToolbar.getCancelButtonInfo()
        ].concat(TooltipToolbar::plantNavMenu[1...])

        controlButtonsMenu: TooltipToolbar::controlButtonsMenu
            .slice(0, -1)
            .concat([
                ActivityEditorToolbar.getOKButtonInfo()
            ])


    class ActivityIntroTooltipToolbar extends TooltipToolbar

        toolbarName: ToolbarEnum.ACTIVITY_INTRO_EDITOR

        initialize: ->
            cancelBtn = ActivityEditorToolbar.getCancelButtonInfo()
            cancelBtn.context.templateString = '<div class="icon icon_back">'
            @plantNavMenu = [
                cancelBtn
            ].concat(TooltipToolbar::plantNavMenu[1...])
            super

        controlButtonsMenu: TooltipToolbar::controlButtonsMenu
            # removing the done button
            .slice(0, -1)
            .concat([
                actionClass: AddOrEditHiddenSound
                viewType: 'button'
                context:
                    templateString: '<div class="icon icon_microphone"></div>'
            ,

                actionClass: GoToActivitySetupMenu
                viewType: 'button'
                context:
                    templateString: '<div class="icon icon_bold-arrow-right"></div>'
            ])


    class DictionaryActivityEditorToolbar extends BuilderToolbar

        defaultState: DictionaryActivityTooltipToolbar::toolbarName

        toolbarClasses: [
            DictionaryActivityTooltipToolbar
            ColorToolbar
        ]


    #
    # ACTIVITY CHOICE
    #
    class ActivityChoiceToolbar extends EditorSubToolbar

        toolbarName: ToolbarEnum.ACTIVITY_CHOICE

        contentMenu: [
            actionClass: SetupPlantToTextActivity
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_doc-with-up-arrow"></div>
                    <div class="button__caption">
                        Create <br />
                        <b>
                            Plant <br />
                            to Text
                        </b>
                    </div>'
        ,

            actionClass: SetupPlantToTextMemoActivity
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_doc-with-up-arrow"></div>
                    <div class="button__caption">
                        Create <br />
                        <b>
                            Plant <br />
                            to Text Read
                        </b>
                    </div>'
        ,

            actionClass: SetupClickActivity
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_pointing-hand"></div>
                    <div class="button__caption">
                        Create <br />
                        <b>Click</b>
                    </div>'
        ]


    class ActivityIntroEditorToolbar extends BuilderToolbar

        defaultState: ActivityIntroTooltipToolbar::toolbarName

        toolbarClasses: [
            ActivityIntroTooltipToolbar
            ColorToolbar
            ActivityChoiceToolbar
        ]


    class ActivityModeEditorToolbar extends ActivityEditorToolbar

        contentMenu: [
            actionClass: SubmitPassiveActivity
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_camera"></div>
                    <div class="button__caption">
                        Make <br />
                        <b>Passive</b> Activity
                    </div>'
        ,
            actionClass: SubmitActiveActivity
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_strategy"></div>
                    <div class="button__caption">
                        Make <br />
                        <b>Active</b> Activity
                    </div>'
        ]

        okNav: null


    class ActivityEditionToolbar extends NavigatorSubToolbar

        toolbarName: ToolbarEnum.ACTIVITY_EDITION

        contentMenu: [
            viewClass: buttons.RemoveSelectedActivityButton
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_trash"></div>
                    <div class="button__caption">
                        Remove <br />
                        <b>Activity</b>
                    </div>'
        ,
            viewClass: buttons.MoveSelectedActivityUpButton
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_arrow-up"></div>
                    <div class="button__caption">
                        Move up <br />
                        <b>Activity</b>
                    </div>'
        ,
            viewClass: buttons.MoveSelectedActivityDownButton
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_arrow-down"></div>
                    <div class="button__caption">
                        Move down <br />
                        <b>Activity</b>
                    </div>'
        ,
            viewClass: buttons.GoToSelectedActivityFromNavigatorButton
            viewType: 'button'
            context:
                templateString: '
                    <div class="icon icon_arrow-right"></div>
                    <div class="button__caption">
                        Go to <br />
                        <b>Activity</b>
                    </div>'
        ]


    module.exports =
        ActivityChoiceToolbar: ActivityChoiceToolbar
        ActivityEditionToolbar: ActivityEditionToolbar
        ActivityIntroEditorToolbar: ActivityIntroEditorToolbar
        P2TActivityEditorToolbar: P2TActivityEditorToolbar
        ClickActivityEditorToolbar: ClickActivityEditorToolbar
        DictionaryActivityEditorToolbar: DictionaryActivityEditorToolbar
        ActivityModeEditorToolbar: ActivityModeEditorToolbar
