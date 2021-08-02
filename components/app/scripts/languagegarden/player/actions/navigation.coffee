'use strict'

_ = require('underscore')
{NavigationAction, UnitAction, Action} = require('./../../common/actions/base')
{GoToTitlePage} = require('./../../common/actions/sidebars')
{GoToActivityList} = require('./../../common/actions/navigation')

###

Low-level navigation actions

###

class GoToLesson extends NavigationAction
    navType: 'play-lesson'

    initialize: (options) ->
        super
        @setPropertyFromOptions(options, 'lessonId', required: true)
        @setPropertyFromOptions(options, 'startPosition')
        @setPropertyFromOptions(options, 'previousPosition')
        @setPropertyFromOptions(options, 'activityId')

    getNavInfo: ->
        type: @navType
        plantId: @lessonId
        startPosition: @startPosition or 0
        previousPosition: @previousPosition
        activityId: @activityId


class GoToActivity extends NavigationAction
    navType: 'play-activity'

    initialize: (options) ->
        super
        @setPropertyFromOptions(options, 'activityId', required: true)
        @setPropertyFromOptions(options, 'lessonId')
        @setPropertyFromOptions(options, 'startPosition')

    getNavInfo: ->
        type: @navType
        activityId: @activityId
        parentPlant:
            id: @lessonId
            startPosition: @startPosition
            navType: 'play-lesson'


###

More complex, sidebar-related actions

###


class UnitSidebarAction extends UnitAction

    initialize: (options) ->
        super
        @options = options
        @setPropertyFromOptions(options, 'chapterIndex', required: true)
        @setPropertyFromOptions(options, 'sidebarTimeline',
                                default: @controller.sidebarTimeline
                                required: true)
        @setPropertyFromOptions(options, 'toolbarView',
                                default: @controller.toolbarView)

    createNavAction: (options) ->
        actionClass = @getNavActionClass(options)
        new actionClass(@getNavActionOptions(options))

    getNavAction: -> @createNavAction(@options)

    ###
    override this method in subclasses
    ###
    getNavActionClass: (options) ->
        null

    getNavActionOptions: (options) ->
        _.extend {}, options,
            startPosition: @chapterIndex
            previousPosition: @getCurrentChapterIndex()
            lessonId: @getLessonId()

    remove: ->
        @options = null
        super

    onPerformStart: ->
        super
        @sidebarTimeline.setBlocked(true)


    ###
    WARNING: This method should be used in places where this.activityRecords
    is provided.
    ###
    isActivityUnlocked: (activityId)->
        activityIds = @getAllActivityIds()
        if not activityIds?
            return false
        blockingIds = (
            @activityRecords.filterBlockingActivityIdsNotCompleted(
                activityIds))
        if activityId in blockingIds
            # Activity is "blocked" which means it was not done. However
            # when the activity is the first, we can do it.
            activityId == blockingIds[0]
        else
            true


###
Base class for sidebar actions used in lesson player
###
class LessonSidebarAction extends UnitSidebarAction

    getCurrentChapterIndex: -> @timeline.getProgressTime()

    getLessonId: -> @dataModel.id

    getAllActivityIds: -> @timeline.getAllActivityIds()

    perform: ->
        indexDelta = @chapterIndex - @getCurrentChapterIndex()
        navAction = @getNavAction()

        if indexDelta == 0
            navAction.fullPerform()

        else if indexDelta in [1, -1]
            @timeline.once 'progresschange', =>
                navAction.fullPerform()

            if indexDelta == 1
                @timeline.shiftToNextStation()
            else
                @timeline.shiftToPreviousStation()

        else
            @timeline.rewind(@chapterIndex)
            navAction.fullPerform()


class GoToLessonFromLessonPlayer extends LessonSidebarAction
    id: 'go-to-lesson'

    getNavActionClass: (options) ->
        # The navigation action is no-op
        UnitAction


class GoToActivityFromLessonPlayer extends LessonSidebarAction
    id: 'go-to-activity'

    initialize: (options) ->
        super
        @setPropertyFromOptions(options, 'activityId', required: true)
        @setPropertyFromOptions(options, 'activityRecords', required: true)
        @setPropertyFromOptions(options, 'sidebarTimeline', required: true)

    getNavActionClass: (options) -> GoToActivity

    perform: ->
        @controller.setDestinationActivityId(@activityId)
        @sidebarTimeline.activateElementByActivityId(@activityId)
        super

    isAvailable: -> @isActivityUnlocked(@activityId)


###
Base class for sidebar actions used in activity player
###
class ActivitySidebarAction extends UnitSidebarAction

    getParentPlantInfo: -> @controller.getParentPlantInfo()

    getSidebarState: ->@controller.sidebarState

    getCurrentChapterIndex: ->
        parentPlantInfo = @getParentPlantInfo()
        parentPlantInfo.startPosition

    getLessonId: ->
        parentPlantInfo = @getParentPlantInfo()
        parentPlantInfo.id or @dataModel.get('parentId')

    getAllActivityIds: ->
        activityIds = []
        {chapters} = @getSidebarState()
        for chapter in chapters.models
            activityIds.push(chapter.elements.pluck('activityId')...)
        activityIds

    perform: ->
        navAction = @getNavAction()
        if @timeline.getProgressTime() > 0
            # there is something to play back, so we play backwards
            # and navigate after the animation finishes
            @toolbarView.setState?('no-op')
            @canvasView.setNoOpMode()
            @timeline.once 'progress:change:start', =>
                navAction.fullPerform()

            @timeline.play(true)
        else
            navAction.fullPerform()


class GoToLessonFromActivityPlayer extends ActivitySidebarAction
    id: 'go-to-lesson'

    getNavActionClass: (options) -> GoToLesson


class GoToActivityFromActivityPlayer extends ActivitySidebarAction
    id: 'go-to-activity'

    initialize: (options) ->
        super
        @setPropertyFromOptions(options, 'activityId', required: true)
        @setPropertyFromOptions(options, 'activityRecords', required: true)
        @setPropertyFromOptions(options, 'sidebarTimeline', required: true)

    getNavActionClass: (options) ->
        currentChapterIndex = @getCurrentChapterIndex()

        if @chapterIndex == currentChapterIndex
            # If the targe chapter index is the same, we can load the
            # activity player directly.
            GoToActivity
        else
            # If the chapters are different, we need to load the lesson player
            # first, to show the animation between chapters. Then,
            # the lesson player should take care of loading the activity player.
            GoToLesson

    perform: ->
        @sidebarTimeline.activateElementByActivityId(@activityId)
        super


    isAvailable: -> @isActivityUnlocked(@activityId)


class GoToNextActivityOrIntro extends UnitAction
    id: 'go-to-next-activity'

    getAction: ->
        nextActivity = @controller.sidebarState.getElementAfterActiveElement()
        sidebarTimeline = @controller.sidebarTimeline

        if nextActivity
            nextChapter = nextActivity.collection.getParentModel()

            if sidebarTimeline.getRootTimeline()?
                action = new GoToActivityFromLessonPlayer
                    controller: @controller
                    chapterIndex: nextChapter.getChapterIndex()
                    activityId: nextActivity.get('activityId')
                    activityRecords: @controller.activityRecords
                    sidebarTimeline: sidebarTimeline
            else
                action = new GoToActivityFromActivityPlayer
                    controller: @controller
                    chapterIndex: nextChapter.getChapterIndex()
                    activityId: nextActivity.get('activityId')
                    activityRecords: @controller.activityRecords
                    sidebarTimeline: sidebarTimeline
        else
            if sidebarTimeline.getRootTimeline()?
                action = new GoToTitlePage
                    controller: @controller
                    sidebarTimeline: sidebarTimeline
            else
                action = new GoToActivityList
                    controller: @controller
                    sidebarTimeline: sidebarTimeline
                    startPosition: 0
        action

    isAvailable: -> @getAction().isAvailable()

    perform: -> @getAction().fullPerform()


class RetryLesson extends Action
    id: 'retry-lesson'

    perform: ->
        lessonId = @controller.dataModel.get('id')
        # TODO: add getActivityIds method to LessonData model
        activityIds = @controller.sidebarState.getElementsIds()
        @controller.activityRecords.resetByLesson(lessonId, activityIds)

        nextActivity = @controller.sidebarState.getElementAfterActiveElement()
        nextActivityChapter = nextActivity.collection.getParentModel()

        action = new GoToActivityFromLessonPlayer
            controller: @controller
            activityId: nextActivity.get('activityId')
            sidebarTimeline: @controller.sidebarTimeline
            activityRecords: @controller.activityRecords
            chapterIndex: nextActivityChapter.getChapterIndex()
        action.fullPerform()


module.exports =
    GoToLessonFromLessonPlayer: GoToLessonFromLessonPlayer
    GoToActivityFromLessonPlayer: GoToActivityFromLessonPlayer
    GoToLessonFromActivityPlayer: GoToLessonFromActivityPlayer
    GoToActivityFromActivityPlayer: GoToActivityFromActivityPlayer
    GoToNextActivityOrIntro: GoToNextActivityOrIntro
    RetryLesson: RetryLesson
