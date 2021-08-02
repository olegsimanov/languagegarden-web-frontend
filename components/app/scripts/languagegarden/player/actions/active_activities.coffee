'use strict'

_ = require('underscore')
{Action} = require('./base')
{MediumType, ActivityType} = require('./../../common/constants')
{getMediumSnapshotByType} = require('../customdiffs/base')


class SubmitAnswer extends Action
    id: 'submit-answer'

    initialize: (options) ->
        super
        @setPropertyFromOptions(options, 'activityRecords',
                                default: @controller.activityRecords
                                required: true)

    getTransformSnapshotFunc: (activityType) ->
        switch (activityType)
            when ActivityType.PLANT_TO_TEXT
                @transfromP2TSnapshot
            when ActivityType.PLANT_TO_TEXT_MEMO
                @transfromP2TSnapshot
            else
                null

    transfromP2TSnapshot: (snapshot) ->
        mediumSnapshot = getMediumSnapshotByType(snapshot,
                                                 MediumType.PLANT_TO_TEXT_NOTE)
        _.map(
            mediumSnapshot.noteTextContent,
            (elements) -> _.map(elements, (el) -> el.text).join('')
        ).join(' ')

    perform: ->
        if not @timeline.endSnapshot?
            return

        expectedSnapshot = @timeline.endSnapshot
        actualSnapshot = @model.toJSON()

        activityType = @dataModel.get('activityType')
        transfromSnapshot = @getTransformSnapshotFunc(activityType)

        if transfromSnapshot
            expectedState = transfromSnapshot(expectedSnapshot)
            actualState = transfromSnapshot(actualSnapshot)
            test = _.isEqual(expectedState, actualState)
        else
            test = _.isEqual(expectedSnapshot, actualSnapshot)

        state = if test then 'answer-ok' else 'answer-invalid'
        @canvasView.setNoOpMode()
        @controller.toolbarView.setState(state)
        if test
            entryData =
                activityId: @dataModel.id
                completed: true
                done: true
            @activityRecords.updateEntry(entryData)
        else
            @increaseFailuresCount()

    increaseFailuresCount: () ->
        activity = @activityRecords.entries.find (e) =>
            e.get('activityId') is @dataModel.id

        unless activity.get('completed')
            activity.set('numOfFailures', activity.get('numOfFailures') + 1)
            @activityRecords.updateEntry(activity)


class RetryActiveActivity extends Action
    id: 'retry-active-activity'

    perform: ->
        if not @controller.isActive()
            return

        @timeline.setActivityStartState()
        @canvasView.setDefaultMode()
        @controller.toolbarView.setState('retry')



module.exports =
    SubmitAnswer: SubmitAnswer
    RetryActiveActivity: RetryActiveActivity
