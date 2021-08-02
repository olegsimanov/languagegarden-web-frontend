    'use strict'

    _ = require('underscore')
    {Action, ToolbarStateAction} = require('./base')
    {ActivityType} = require('./../../common/constants')
    {ToolbarEnum} = require('./../../common/views/toolbars/constants')
    {GoToActivityFromNavigator} = require('./../../common/actions/navigation')


    class SidebarToolbarStateAction extends ToolbarStateAction

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'sidebarTimeline',
                                    default: @controller.sidebarTimeline
                                    required: true)


    class GoToActivitySetupMenu extends ToolbarStateAction
        id: 'go-to-activity-setup-menu'
        state: ToolbarEnum.ACTIVITY_CHOICE


    class GoToActivityEditionMenu extends SidebarToolbarStateAction
        state: ToolbarEnum.ACTIVITY_EDITION

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'activityId', required: true)

        perform: ->
            @sidebarTimeline.activateElementByActivityId(@activityId)
            super


    class CreateActivity extends Action

        isAvailable: -> true

        perform: ->
            navInfo =
                type: 'add-activity'
                plantId: @controller.dataModel.id
            @parentView.trigger('navigate', @parentView, navInfo)


    class SetupActivity extends Action
        activityType: 'unspecified'

        isAvailable: -> true

        perform: ->
            navInfo =
                type: 'add-activity-next'
                plantId: @controller.dataModel.id
                activityType: @activityType
            @parentView.trigger('navigate', @parentView, navInfo)


    class SetupPlantToTextActivity extends SetupActivity
        activityType: ActivityType.PLANT_TO_TEXT
        id: 'create-plant-to-text-activity'


    class SetupPlantToTextMemoActivity extends SetupActivity
        activityType: ActivityType.PLANT_TO_TEXT_MEMO
        id: 'create-plant-to-text-memo-activity'


    class SetupClickActivity extends SetupActivity
        activityType: ActivityType.CLICK
        id: 'create-click-activity'


    class GoToPlantNavigator extends Action

        isAvailable: -> true

        getNavInfo: ->
            type: 'nav-plant'
            plantId: @controller.dataModel.get('parentId')

        perform: ->
            navInfo = @getNavInfo()
            @parentView.trigger('navigate', @parentView, navInfo)


    class SubmitActivity extends GoToPlantNavigator
        id: 'submit-activity'

        perform: ->
            @timeline.saveModel()
            @dataModel.once 'sync', =>
                super

    class SubmitActiveActivity extends SubmitActivity
        id: 'submit-active-activity'

        perform: ->
            @dataModel.set('passive', false)
            @dataModel.set('active', true)
            super


    class SubmitPassiveActivity extends SubmitActivity
        id: 'submit-passive-activity'

        perform: ->
            @dataModel.set('passive', true)
            @dataModel.set('active', false)
            super


    class ContinueActivity extends GoToPlantNavigator
        id: 'continue-activity'

        getNavInfo: ->
            dataModel = @controller.dataModel
            type: 'add-activity-next'
            plantId: dataModel.get('parentId')
            activityType: dataModel.get('activityType')


    class FinalizeActivity extends GoToPlantNavigator
        id: 'finalize-activity'

        getNavInfo: ->
            dataModel = @controller.dataModel
            type: 'add-activity-final'
            plantId: dataModel.get('parentId')
            activityType: dataModel.get('activityType')


    class CancelActivity extends GoToPlantNavigator
        id: 'cancel-activity'


    class BaseActivityAction extends Action
        saveModelAtEnd: true

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'history',
                                    default: @controller.history,
                                    required: true)

        getActivityId: ->
            console.log('getActivityId is undefined!')
            null

        isAvailable: -> @getActivityId()?

        onPerformEnd: ->
            super
            if @saveModelAtEnd
                @timeline.saveModel()


    class BaseSelectedActivityAction extends BaseActivityAction

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'sidebarTimeline',
                                    default: @controller.sidebarTimeline
                                    required: true)

        getActiveChapter: ->
            sidebarState = @sidebarTimeline.getSidebarState()
            sidebarState.getActiveChapter()

        getActiveChapterElement: -> @getActiveChapter()?.getActiveElement()

        getActiveChapterElementIndex: ->
            @getActiveChapter()?.getActiveElementIndex()

        getActiveChapterElementsLength: ->
            @getActiveChapter()?.elements.length

        setActiveChapterElementIndex: (index, options) ->
            @getActiveChapter()?.activateElementByIndex(index, options)

        activateElementByActivityId: (activityId) ->
            @sidebarTimeline.activateElementByActivityId(activityId)

        getActivityId: -> @getActiveChapterElement()?.get('activityId')


    removePerform = ->
        @timeline.removeActivityLink
            activityId: @getActivityId()


    class RemoveActivity extends BaseActivityAction
        id: 'remove-activity'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'activityLink', required: true)

        getActivityId: -> @activityLink.get('activityId')

        perform: removePerform


    class RemoveSelectedActivity extends BaseSelectedActivityAction
        id: 'remove-active-activity'

        perform: removePerform


    class MoveSelectedActivityByDelta extends BaseSelectedActivityAction
        delta: 0

        getNewIndex: -> @getActiveChapterElementIndex() + @delta

        isAvailable: ->
            if not super
                return false
            newIndex = @getNewIndex()
            elemsLen = @getActiveChapterElementsLength()
            0 <= newIndex and newIndex < elemsLen

        perform: ->
            # the activity id will be destroyed, so we temporarily
            # store it here
            @lastActivityId = @getActivityId()
            sourceIndex = @getActiveChapterElementIndex()
            newIndex = @getNewIndex()
            @timeline.repositionActivityLink(sourceIndex, newIndex)

        onPerformEnd: ->
            super
            @activateElementByActivityId(@lastActivityId)
            @lastActivityId = null


    class MoveSelectedActivityUp extends MoveSelectedActivityByDelta
        id: 'move-active-activity-up'
        delta: -1


    class MoveSelectedActivityDown extends MoveSelectedActivityByDelta
        id: 'move-active-activity-down'
        delta: 1


    class GoToSelectedActivityFromNavigator extends BaseSelectedActivityAction
        saveModelAtEnd: false

        getSubAction: ->
            new GoToActivityFromNavigator
                controller: @controller
                activityId: @getActivityId()

        perform: ->
            action = @getSubAction()
            action.fullPerform()

        isAvailable: ->
            if not super
                return false
            action = @getSubAction()
            action.isAvailable()


    module.exports =
        GoToActivitySetupMenu: GoToActivitySetupMenu
        GoToActivityEditionMenu: GoToActivityEditionMenu
        CreateActivity: CreateActivity
        SetupPlantToTextActivity: SetupPlantToTextActivity
        SetupPlantToTextMemoActivity: SetupPlantToTextMemoActivity
        SetupClickActivity: SetupClickActivity
        SubmitActiveActivity: SubmitActiveActivity
        SubmitPassiveActivity: SubmitPassiveActivity
        ContinueActivity: ContinueActivity
        FinalizeActivity: FinalizeActivity
        CancelActivity: CancelActivity
        RemoveActivity: RemoveActivity
        RemoveSelectedActivity: RemoveSelectedActivity
        MoveSelectedActivityUp: MoveSelectedActivityUp
        MoveSelectedActivityDown: MoveSelectedActivityDown
        GoToSelectedActivityFromNavigator: GoToSelectedActivityFromNavigator
