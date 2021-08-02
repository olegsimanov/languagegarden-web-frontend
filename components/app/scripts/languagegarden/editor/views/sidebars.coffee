    'use strict'

    _ = require('underscore')
    {BaseView} = require('./../../common/views/base')
    {
        TileElementView
        TileElementsView
        SidebarTileView
        SidebarTilesView
        TitlePageImageView
        SidebarView
    } = require('./../../common/views/sidebars')
    {GoToStationFromNavigator} = require('./../../common/actions/navigation')
    {disableSelection} = require('./../../common/domutils')
    {GoToStationCreationMenu} = require('./../actions/navigation')
    {
        CreateActivity
        GoToActivityEditionMenu
    } = require('./../actions/activities')
    {GoToSidebarChapter, GoToTitlePage} = require('./../actions/sidebars')
    {template} = require('./../../common/templates')


    class EditorTileElementView extends TileElementView

        initializeAction: (options) ->
            if @sidebarTimeline.getRootTimeline()?
                @initializeActionForPlantNavigator(options)
            else
                @initializeActionForActivityPlayer(options)

        initializeActionForPlantNavigator: (options) ->
            chapter = @model.collection.getParentModel()
            @action = new GoToActivityEditionMenu
                controller: @controller
                sidebarTimeline: @sidebarTimeline
                activityId: @model.get('activityId')
                timeline: @sidebarTimeline.getRootTimeline()
                position: chapter.getChapterIndex()


    class EditorTileElementsView extends TileElementsView
        itemViewClass: EditorTileElementView


    class AddActivityElementView extends BaseView
        events:
            'click': 'onClick'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'sidebarTimeline', required: true)
            @initializeAction(options)

        initializeAction: (options) ->
            @action = new CreateActivity
                controller: @controller
                sidebarTimeline: @sidebarTimeline

        render: ->
            disableSelection(@el)
            super

        onClick: (event) ->
            event.preventDefault()
            if @action.isAvailable()
                @action.fullPerform()


    class EditorSidebarTileView extends SidebarTileView
        template: template('./editor/sidebars/tile.ejs')
        elementsViewClass: EditorTileElementsView

        getTileSubviews: (options) ->
            data = super
            @addActivityElementView = new AddActivityElementView(options)
            data['.tile__element--add'] = @addActivityElementView
            data

        initializeAction: (options) ->
            @initializeActionForPlantNavigator(options)

        initializeActionForPlantNavigator: (options) ->
            @action = new GoToSidebarChapter
                controller: @controller
                toolbarView: @controller.toolbarView
                sidebarTimeline: @sidebarTimeline
                activityRecords: @activityRecords
                chapterIndex: @model.getChapterIndex()

        remove: ->
            @addActivityElementView.remove()
            super


    class EditorSidebarTilesView extends SidebarTilesView
        itemViewClass: EditorSidebarTileView


    class AddStationTileView extends BaseView
        events:
            'click': 'onClick'

        initialize: (options) ->
            super
            @initializeAction(options)

        initializeAction: (options) ->
            @action = new GoToStationCreationMenu
                controller: @controller

        render: ->
            disableSelection(@el)
            super

        onClick: (event) ->
            event.preventDefault()
            if @action.isAvailable()
                @action.fullPerform()


    class EditorTitlePageImageView extends TitlePageImageView
        actionClass: GoToTitlePage


    class EditorSidebarView extends SidebarView
        template: template('./editor/sidebars/base.ejs')
        tilesViewClass: EditorSidebarTilesView
        titlePageImageViewClass: EditorTitlePageImageView

        getSidebarSubviews: (options) ->
            data = super
            @addStationTileView = new AddStationTileView(options)
            data['.sidebar__tile--add'] = @addStationTileView
            data

        getRenderContext: ->
            ctx = super
            ctx.backURL = @controller.backURL
            ctx

        remove: ->
            @addStationTileView.remove()
            super

        renderCore: ->
            super
            @$el.toggleClass('sidebar--disabled', @sidebarTimeline.isBlocked())
            @$('.sidebar__overlay').toggleClass('sidebar__overlay--visible',
                                                @sidebarTimeline.isBlocked())


    module.exports =
        EditorSidebarView: EditorSidebarView
