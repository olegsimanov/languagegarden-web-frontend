    'use strict'

    _ = require('underscore')
    settings = require('./../settings')
    {BaseController} = require('./../common/controllers')
    {PlantMetaCollection} = require('./../common/models/plantlists')
    {PlantListView} = require('./views/plantlists')
    {LetterMetrics} = require('./../common/svgmetrics')
    {ListPageView} = require('./views/page/base')
    {ActivityType} = require('./../common/constants')


    class ListController extends BaseController

        initialize: (options) ->
            super
            @collection = new PlantMetaCollection([],
                limit: 10
                filters:
                    'format_type': 'html5'
            )
            @listView = new PlantListView
                collection: @collection

            @view = new ListPageView
                controller: this
                subviews:
                    '.list-container .list': [@listView]
                containerEl: @containerElement

            @pageNumber = options.pageNumber

            # hack used for preloading font
            @letterMetrics = new LetterMetrics()
            @letterMetrics.getLength('A', 20)

            @listenTo(@listView, 'navigate', @onObjectNavigate)
            @listenTo(@collection, 'navigate', @onObjectNavigate)
            @listenTo(@collection, 'sync', @onCollectionSync)

        remove: ->
            @letterMetrics.remove()
            views = [@view]
            for obj in views
                @stopListening(obj)
                obj.remove()
            @collection.reset()
            @collection.off()
            @stopListening(@collection)
            @stopListening(@listView)
            @collection = null
            @view = null
            @listView = null
            super

        start: (options) ->
            pageNumber = options?.pageNumber or @pageNumber
            @setPageNumber(pageNumber, options)

        setPageNumber: (pageNumber, options) ->
            [triggerSuccess, triggerError] = @getTriggeringCallbacks(options)

            if pageNumber > 0
                @collection.page = pageNumber - 1
            else
                @collection.page = 0
            @collection.fetch
                success: triggerSuccess
                error: triggerError

        onCollectionSync: ->
            @view.render()
            @listView.render()


    module.exports =
        ListController: ListController
