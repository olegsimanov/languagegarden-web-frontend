    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    metrics = require('./models/metrics')


    {Metrics} = metrics

    class KeyListener

        constructor: (@el, @metric) ->
            $(@el).on('keyup', @onDocumentKeyUp)
            @namespace = 'key'

        getMetric: (namespace=@namespace) =>
            metric = if _.isFunction(@metric) then @metric() else @metric
            metric.subMetric(namespace)

        onDocumentKeyUp: (event) => @getMetric().increment()

        remove: =>
            $(@el).off('keyup', @onDocumentKeyUp)

    class MouseListener

        constructor: (@el, @metric) ->
            $(@el)
                .on('click', @onDocumentClick)
            @namespace = 'click'

        getMetric: (namespace=@namespace) =>
            metric = if _.isFunction(@metric) then @metric() else @metric
            metric.subMetric(namespace)

        onDocumentClick: (event) => @getMetric().increment()

        remove: =>
            $(@el).off('click', @onDocumentClick)


    module.exports =
        KeyListener: KeyListener
        MouseListener: MouseListener
