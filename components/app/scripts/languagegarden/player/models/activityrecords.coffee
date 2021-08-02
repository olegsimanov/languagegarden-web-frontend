    'use strict'

    _ = require('underscore')
    Backbone = require('backbone')
    $ = require('jquery')
    {
        BaseModel
        BaseCollection
        BaseModelWithSubCollections
    } = require('./../../common/models/base')
    require('backbone.localStorage')

    INFO_SAVED = 'saved'
    INFO_UNSAVED = 'unsaved'


    class RecordEntry extends BaseModel
        idAttribute: 'activityId'
        defaults:
            visited: false
            seen: false
            done: false
            completed: false
            numOfFailures: 0


    class RecordEntries extends BaseCollection
        model: RecordEntry

        # TODO: refactor SubCollectionPrototype
        setParentModel: (model) -> @parentModel = model


    class LessonInfo extends BaseModel
        idAttribute: 'lessonId'
        defaults:
            state: INFO_UNSAVED


    class LessonInfos extends BaseCollection
        model: LessonInfo

        # TODO: refactor SubCollectionPrototype
        setParentModel: (model) -> @parentModel = model


    class ActivityRecords extends BaseModelWithSubCollections
        defaults: {}
        subCollectionConfig: [
            name: 'entries'
            collectionClass: RecordEntries
        ,
            name: 'infos'
            collectionClass: LessonInfos
        ]

        initialize: (options)->
            super
            @localStorage = new Backbone.LocalStorage('activityRecords')
            @filterActivityIdsNotSeen = @filterActivityIdsNotHaving('seen')
            @filterBlockingActivityIdsNotSeen = (
                @filterBlockingActivityIdsNotHaving('seen')
            )
            @filterActivityIdsNotCompleted = (
                @filterActivityIdsNotHaving('completed')
            )
            @filterBlockingActivityIdsNotCompleted = (
                @filterBlockingActivityIdsNotHaving('completed')
            )

        getActivityIdsHaving: (propName) ->
            (e.get('activityId') for e in @entries.filter((e) ->
                e.get(propName)))

        getEntriesByActivityIds: (activityIds) ->
            @entries.filter (e) -> e.get('activityId') in activityIds

        ###
        Returns the activity ids from the activityIds parameter which
        do not have given property (for instance, 'seen', 'visited', 'done')
        preserving the order of this parameter list.
        ###
        filterActivityIdsNotHaving: (propName) ->
            (activityIds) =>
                activityIdsNotHaving = []
                activityIdsHaving = @getActivityIdsHaving(propName)
                for activityId in activityIds
                    if not (activityId in activityIdsHaving)
                        activityIdsNotHaving.push(activityId)

                activityIdsNotHaving

        ###
        Returns the slice from the activityIds parameter
        where the first activity id is not having given property
        (for instance, 'seen', 'visited', 'done').
        ###
        filterBlockingActivityIdsNotHaving: (propName) ->
            (activityIds) =>
                activityIdsHaving = @getActivityIdsHaving(propName)
                for i in [0...activityIds.length]
                    if not (activityIds[i] in activityIdsHaving)
                        # first encouter of activity id which does not
                        # have given property, so we assume that
                        # the rest should be blocked
                        return activityIds[i..]
                []

        entryHasProperty: (activityId, propName) ->
            model = @entries.get(activityId)
            if model?
                model.get(propName)
            else
                false

        createInitialEntryByActivityId: (activityId) ->
            data =
                activityId: activityId
            @entries.add(data)

        updateEntry: (entryModel, options) ->
            options = _.extend({merge: true}, options)
            @entries.add(entryModel, options)
            @save()

        retrieveLessonInfo: (lessonId) ->
            lessonInfo = @infos.get(lessonId)
            if not lessonInfo?
                lessonInfo = new LessonInfo(lessonId: lessonId)
                @infos.add(lessonInfo)
            lessonInfo

        syncByLesson: (lessonId, activityIds) ->
            lessonInfo = @retrieveLessonInfo(lessonId)
            @save()
            if lessonInfo.get('state') == INFO_SAVED
                return false
            activityRecords = @getEntriesByActivityIds(activityIds)
            if activityRecords.length != activityIds.length
                return false
            if not _.all(activityRecords, (record) -> record.get('completed'))
                return false
            data = {
                'lesson_id': lessonId
                'activity_records': []
            }
            for activityRecord in activityRecords
                activityData = {}

                for key in ['visited', 'seen', 'done', 'completed']
                    activityData[key] = activityRecord.get(key)

                activityData['activity_id'] = activityRecord.get('activityId')
                activityData['num_of_failures'] = activityRecord.get('numOfFailures')

                data.activity_records.push(activityData)

            Backbone.ajax
                url: '/api/v2/lesson_records/'
                method: 'POST'
                contentType: 'application/json'
                data: JSON.stringify(data)
                beforeSend: (xhr) ->
                    csrftoken = $.cookie('csrftoken')
                    xhr.setRequestHeader('X-CSRFToken', csrftoken);
                success: =>
                    successlessonInfo = @retrieveLessonInfo(lessonId)
                    successlessonInfo.set('state', INFO_SAVED)
                    @save()

        resetByLesson: (lessonId, activityIds) ->
            records = @getEntriesByActivityIds(activityIds)
            lessonInfo = @retrieveLessonInfo(lessonId)
            @entries.remove(records)
            lessonInfo.set('state', INFO_UNSAVED)
            @save()

        @getRecords = (name='Anon') =>
            @_instances ?= {}
            if not @_instances[name]?
                records = new this(id: name)
                records.fetch(async: false)
                records
                @_instances[name] = records

            @_instances[name]


    module.exports =
        ActivityRecords: ActivityRecords
