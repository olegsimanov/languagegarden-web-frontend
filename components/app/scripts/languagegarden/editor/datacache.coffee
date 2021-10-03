'use strict'

_ = require('underscore')
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
        @lessons = {}
        @state = STATE_READY

    getLessonPayload: (lessonId) -> @lessons[lessonId] or null

    clear: ->
        @lessons = {}
        @state = STATE_READY
        return


module.exports =
    UnitDataCache: UnitDataCache
