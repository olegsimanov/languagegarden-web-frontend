    'use strict'

    _ = require('underscore')
    settings = require('./../../settings')
    baseModels = require('./../../common/models/base')
    metricConstants = require('./../constants')
    localstorage = require('./../../common/localstorage')


    {
        BaseModel,
        BaseCollection,
    } = baseModels
    {MetricType} = metricConstants
    {LocalStorage} = localstorage


    class Metric

        defaultStoreInterval: 60

        constructor: (options) ->
            ## storage interaction
            @storage = LocalStorage.getInstance()
            @namespace = options.namespace
            @data = []
            @storeInterval = options.storeInterval
            @load() if options.load

        save: ->
            if @storage.enabled
                @storage.set(@namespace, @data)
            console.log(@namespace) if settings.logMetrics
        load: ->
            if @storage.enabled
                @data = @storage.get(@namespace) or []

        ## reporting metric data

        ###Adds a timed event into the store, aggregates stats on intervals.
        Pass options.storeInterval to control the interval.
        ###
        increment: (namespace, increment=1, options={}) =>
            @load() if options.sync
            timestamp = options.timestamp or @now()
            storeInterval = (
                options.storeInterval or @storeInterval or @defaultStoreInterval
            )
            last = @data[@data.length - 1]
            if last? and @now() - last.timestamp < storeInterval
                # if still withing storeInterval of last entry, just increment
                last.value += increment
            else
                if last?
                    # if there is last entry, byt further than @storeInterval
                    # away, skip creating buckets, but ensure even bucket start
                    timestamp = last.timestamp + Math.floor(
                        (timestamp - last.timestamp) / storeInterval
                    ) * storeInterval
                @data.push(
                    timestamp: timestamp
                    value: increment
                )
            @save()

        ###Adds a timed event into the store, does not perform any aggregation.
        ###
        append: (namespace, value=undefined, timestamp, sync=false) =>
            @load() if sync
            timestamp ?= @now()
            @data.push(timestamp)
            @save()

        now: => new Date().getTime() / 1000

        subMetric: (namespace, options) =>
            Metrics.getMetric("#{@namespace}.#{namespace}", options)


    class Metrics

        @metrics = {}

        @getMetric = (namespace, options={}) =>
            metric = @metrics[namespace]
            load = if options.load? then options.load

            if not metric?
                load ?= true
                options = _.extend({}, options)
                options.namespace = namespace
                metric = new Metric(options)
                @metrics[namespace] = metric

            metric.load() if load
            metric


    module.exports =
        Metric: Metric
        Metrics: Metrics
