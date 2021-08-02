'use strict'

_ = require('underscore')
Backbone = require('backbone')
$ = require('jquery')
settings = require('./../settings')
config = require('./../config')
{EventObject} = require('./events')
{deepCopy} = require('./utils')

STATE_READY = 1
STATE_LOADING = 2


class UnitDataCache extends EventObject

    @getInstance: ->
        if not this._instance?
            @factoryRunningFlag = true
            this._instance = new this()
            @factoryRunningFlag = false

        this._instance

    initialize: (options) ->
        if not UnitDataCache.factoryRunningFlag
            throw "please use the getInstance class method"
        @activities = {}
        @lessons = {}
        @state = STATE_READY

    isReady: -> @state == STATE_READY

    loadActivitiesByLessonId: (lessonId, success, error) ->
        queryString = $.param
            'lesson_id': lessonId
            'page_size': 1000
            'full': true
        activitiesUrl = config.getUrlRoot(settings.apiResourceNames.activities)
        url = "#{activitiesUrl}?#{queryString}"
        Backbone.ajax
            url: url
            dataType: 'json'
            success: success
            error: error

    _populateActivity: (activityData) ->
        @activities[activityData.id] = deepCopy(activityData)

    _triggerChange: (options) ->
        silent = options?.silent or false
        if not silent
            @trigger('populate', this)
        return

    populateActivity: (activityData, options) ->
        @_populateActivity(activityData)
        @_triggerChange(options)

    populateActivities: (activityDataList, options) ->
        for activityData in activityDataList
            @_populateActivity(activityData)
        @_triggerChange(options)

    populateLesson: (lessonData, options) ->
        @lessons[lessonData.id] = deepCopy(lessonData)
        @_triggerChange(options)

    populateActivitiesByLessonId: (lessonId, options) ->
        success = options?.success or ->
        error = options?.error or ->
        successWrapper = (data) =>
            results = data?.results or []
            @populateActivities(results)
            @state = STATE_READY
            success()
        @state = STATE_LOADING
        @loadActivitiesByLessonId(lessonId, successWrapper, error)

    getActivityPayload: (activityId) -> @activities[activityId] or null

    getLessonPayload: (lessonId) -> @lessons[lessonId] or null

    getActivityIds: -> _.keys(@activities)

    getLessonIds: -> _.keys(@lessons)

    getActivitiesJSONByIds: (idsArray) ->
        results = []
        for id in idsArray
            activity = @activities[id]
            if activity
                results.push(JSON.parse(activity.data))
        results

    clear: ->
        @activities = {}
        @lessons = {}
        @state = STATE_READY
        return


module.exports =
    UnitDataCache: UnitDataCache
