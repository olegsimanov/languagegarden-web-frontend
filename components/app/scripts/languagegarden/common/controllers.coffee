    'use strict'

    require('../../polyfills/request-animation-frame')

    _ = require('underscore')
    $ = require('jquery')
    require('../../../styles/layout.less')
    require('../../../font/languagegarden-regular-webfont.css')
    require('../../../font/eskorte-arabic-regular-webfont.css')
    require('../../../styles/iefix.less')

    require('../../iefix')
    {EventObject} = require('./events')


    class BaseController extends EventObject

        constructor: (options) ->
            @cid = _.uniqueId('controller')
            @bus = new EventObject()
            super

        initialize: (options) ->
            super
            @containerElement = options.containerElement or document.body
            @backURL = options.backURL or '/'

        remove: ->
            @bus.stopListening()
            @bus.off()
            @off()
            super

        getTriggeringCallbacks: (options) ->
            successCallback = options?.success or ->
            errorCallback = options?.error or ->

            triggerSuccess = =>
                successCallback()
                @trigger('start:success', this)

            triggerError = =>
                errorCallback()
                @trigger('start:error', this)

            [triggerSuccess, triggerError]

        start: (options) ->
            [triggerSuccess, triggerError] = @getTriggeringCallbacks(options)
            triggerSuccess()

        getAnalyticsData: ->

        onObjectNavigate: (source, navigationInfo) ->
            @trigger('navigate', source, navigationInfo)


    module.exports =
        BaseController: BaseController
