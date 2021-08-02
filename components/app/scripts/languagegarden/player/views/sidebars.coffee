    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    Hammer = require('hammerjs')
    {SidebarView, TileElementView} = require('./../../common/views/sidebars')
    {disableSelection} = require('./../../common/domutils')
    {BaseView} = require('./../../common/views/base')
    {RenderableView} = require('./../../common/views/renderable')
    {template} = require('./../../common/templates')
    {
        GoToActivityFromLessonPlayer
        GoToActivityFromActivityPlayer
    } = require('./../actions/navigation')
    {GoToSidebarChapter} = require('./../../common/actions/sidebars')


    class PlayerSidebarActivityButtonView extends RenderableView
        renderChangedHTML: true
        className: 'sidebar__tile tile sidebar__tile--as-tile-element'
        template: template('./common/sidebars/tile.ejs')

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'itemNumber', required: true)
            @setPropertyFromOptions(options, 'chapterIndex', required: true)
            @setPropertyFromOptions(options, 'sidebarTimeline', required: true)
            @setPropertyFromOptions(options, 'activityRecords',
                                    default: @controller?.activityRecords)
            if @activityRecords?
                @listenTo(@activityRecords.entries, 'change', @onActivityRecordsChange)
            @action = @createAction(options)
            @listenTo(@model, 'activate', @onChapterElementActivate)
            Hammer(@el).on('tap', (event) => @onClick(event))

        remove: ->
            @action = null
            super

        getRenderContext: ->
            number: @itemNumber

        isLessonContext: -> @sidebarTimeline.getRootTimeline()?

        renderCore: ->
            super
            @$el.toggleClass('sidebar__tile--active', @model.isActive())
            @$el.toggleClass('sidebar__tile--locked', not @action.isAvailable())

        onClick: (event) ->
            event.preventDefault()
            @action.fullPerform()

        createAction: (options) ->
            opts = _.extend {}, options,
                activityId: @model.get('activityId')
            opts.activityRecords ?= @activityRecords
            if @isLessonContext()
                actionClass = GoToActivityFromLessonPlayer
            else
                actionClass = GoToActivityFromActivityPlayer
            new actionClass(opts)

        onActivityRecordsChange: -> @invalidate()

        onChapterElementActivate: -> @invalidate()


    class PlayerSidebarTilesView extends BaseView
        activityItemViewClass: PlayerSidebarActivityButtonView
        activityViews: []

        initialize: (options) ->
            @setOption(options, 'sidebarTimeline', null, true)

        render: ->
            @removeActivityViews()
            itemNumber = 1
            @collection.each (chapter) =>
                chapter.elements.each (activity) =>
                    view = new @activityItemViewClass
                        model: activity
                        sidebarTimeline: @sidebarTimeline
                        controller: @controller
                        chapterIndex: chapter.getChapterIndex()
                        itemNumber: itemNumber
                    view.render()
                    @$el.append(view.el)
                    @activityViews.push(view)
                    itemNumber++

        removeActivityViews: ->
            for view in @activityViews
                view.remove()
            @activityViews = []

        remove: ->
            @removeActivityViews()
            super

        getTileElByActivityId: (activityId) ->
            for view in @activityViews
                if view.model.get('activityId') is activityId
                    return view.$el


    class PlayerSidebarView extends SidebarView
        tilesViewClass: PlayerSidebarTilesView
        className: "#{SidebarView::className} sidebar_in-player"

        initialize: ->
            super
            @listenTo(@sidebarTimeline, 'blocked:change', @toggleBlocked)
            @listenTo(
                @sidebarTimeline.getSidebarState()
                'change:activeElementIndex'
                @onActiveElementIndexChange
            )

        render: ->
            super
            @toggleBlocked()

        toggleBlocked: () ->
            @$el.toggleClass('sidebar_blocked', @sidebarTimeline.isBlocked())

        scrollToTile: (activityId) ->
            $tile = @tilesView.getTileElByActivityId(activityId)

            containerHeight = @$tilesContainerEl.height()
            tileHeight = $tile.outerHeight(true)
            tileOffset = tileHeight * $tile.index()
            containerOffset = (containerHeight - tileHeight) / 2

            jsp = @$tilesContainerEl.data('jsp')
            jsp.scrollToY(tileOffset - containerOffset, false)

        onActiveElementIndexChange: (chapter, elementIndex) ->
            if elementIndex?
                activityId = chapter.elements.at(elementIndex).get('activityId')
                @scrollToTile(activityId)


    module.exports =
        PlayerSidebarView: PlayerSidebarView
