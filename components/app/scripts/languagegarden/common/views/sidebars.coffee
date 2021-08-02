    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    Hammer = require('hammerjs')
    require('jquery.jscrollpane.custom')
    require('jquery.mousewheel')
    require('mwheelIntent')
    {getCharRange} = require('./../utils')
    {disableSelection} = require('./../domutils')
    {BaseView} = require('./base')
    {RenderableView} = require('./renderable')
    {BaseCollectionView} = require('./collections')
    {
        GoToActivityFromPlantPlayer
        GoToActivityFromActivityPlayer
        GoToActivityList
    } = require('./../actions/navigation')
    {GoToSidebarChapter, GoToTitlePage} = require('./../actions/sidebars')
    {template} = require('./../templates')


    class TileElementView extends BaseView
        className: 'tile__element element'

        initializeProperties: (options) ->
            @setPropertyFromOptions(options, 'sidebarTimeline', required: true)
            @setPropertyFromOptions(options, 'activityRecords',
                                    default: @controller?.activityRecords)

        initialize: (options) ->
            super
            @letters = getCharRange('a', 'z')
            @initializeProperties(options)
            @initializeAction(options)
            if @activityRecords?
                @listenTo(@activityRecords, 'change', @onActivityRecordsChange)
                @listenTo(@activityRecords.entries, 'all',
                          @onActivityRecordsChange)

            Hammer(@el).on('tap', (event) => @onClick(event))

        initializeAction: (options) ->
            if @sidebarTimeline.getRootTimeline()?
                @initializeActionForPlantPlayer(options)
            else
                @initializeActionForActivityPlayer(options)

        initializeActionForPlantPlayer: (options) ->
            chapter = @model.collection.getParentModel()
            @action = new GoToActivityFromPlantPlayer
                controller: @controller
                sidebarTimeline: @sidebarTimeline
                activityRecords: @activityRecords
                activityId: @model.get('activityId')
                timeline: @sidebarTimeline.getRootTimeline()
                position: chapter.getChapterIndex()

        initializeActionForActivityPlayer: (options) ->
            chapter = @model.collection.getParentModel()
            @action = new GoToActivityFromActivityPlayer
                controller: @controller
                sidebarTimeline: @sidebarTimeline
                activityRecords: @activityRecords
                activityId: @model.get('activityId')
                chapterIndex: chapter.getChapterIndex()

        remove: ->
            if @activityRecords?
                @stopListening(@activityRecords)
                @stopListening(@activityRecords.entries)
            super

        render: ->
            number = @model.getElementIndex()
            letter = @letters[number % @letters.length]
            disableSelection(@el)
            @$el.text(letter)
            @$el.toggleClass('tile__element--active', @model.isActive())
            @$el.toggleClass('tile__element--disabled',
                             not @action.isAvailable())
            super

        onActivityRecordsChange: -> @invalidate()

        onClick: (event) ->
            event.preventDefault()
            if @action.isAvailable()
                @action.fullPerform()


    class TileElementsView extends BaseCollectionView
        itemViewClass: TileElementView

        initialize: (options) ->
            super
            @setOption(options, 'sidebarTimeline', null, true)

        getItemViewOptions: (model) ->
            options = super
            options.sidebarTimeline = @sidebarTimeline
            options


    class SidebarTileView extends RenderableView
        className: 'sidebar__tile tile'
        template: template('./common/sidebars/tile.ejs')
        elementsViewClass: TileElementsView
        events:
            'click .tile__number-container': 'onNumberClick'

        initializeProperties: (options) ->
            @setPropertyFromOptions(options, 'sidebarTimeline', required: true)

        initialize: (options) ->
            @initializeProperties(options)
            options = _.clone(options)
            options.subviews ?= {}
            _.extend(options.subviews, @getTileSubviews(options))
            super(options)
            @initializeAction(options)

        getTileSubviews: (options) ->
            elementsOptions = _.clone(options)
            elementsOptions.collection = @model.elements
            @elementsView = new @elementsViewClass(elementsOptions)

            '.tile__elements': @elementsView

        initializeAction: (options) ->
            if @sidebarTimeline.getRootTimeline()?
                @initializeActionForPlantPlayer(options)
            else
                @initializeActionForActivityPlayer(options)

        initializeActionForPlantPlayer: (options) ->
            @action = new GoToSidebarChapter
                controller: @controller
                sidebarTimeline: @sidebarTimeline
                activityRecords: @activityRecords
                chapterIndex: @model.getChapterIndex()

        initializeActionForActivityPlayer: (options) ->
            @action = new GoToActivityList
                controller: @controller
                sidebarTimeline: @sidebarTimeline
                activityRecords: @activityRecords
                startPosition: @model.getChapterIndex()

        remove: ->
            @stopListening(@elementsView)
            super

        render: ->
            disableSelection(@el)
            @$el.toggleClass('sidebar__tile--active', @model.isActive())
            @$el.toggleClass('sidebar__tile--disabled',
                             not @action.isAvailable())
            super

        getRenderContext: ->
            ctx = super
            ctx.number = @model.getChapterIndex()
            ctx

        onModelBind: ->
            super
            @listenTo(@model, 'change:activeElementIndex',
                      @onModelActiveElementIndexChange)

        onModelActiveElementIndexChange: ->
            @invalidate()

        onNumberClick: (event) ->
            event.preventDefault()
            @action.fullPerform()


    class SidebarTilesView extends BaseCollectionView
        itemViewClass: SidebarTileView

        initialize: (options) ->
            super
            @setOption(options, 'sidebarTimeline', null, true)
            @listenTo(@sidebarTimeline, 'progresschange', @onPositionChange)
            @listenTo(@collection, 'all', @onCollectionChange)

        remove: ->
            @stopListening(@sidebarTimeline)
            @stopListening(@collection)
            super

        getItemViewOptions: (model) ->
            options = super
            options.sidebarTimeline = @sidebarTimeline
            options

        createItemView: (model) ->
            if model.getChapterIndex() > 0
                super
            else
                # do not show the '0'th chapter
                null

        onPositionChange: ->

        onCollectionChange: ->
            @render()


    class TitlePageImageView extends RenderableView
        actionClass: GoToTitlePage
        template: template('./common/sidebars/title-page-image.ejs')
        events:
            'click': 'onClick'

        initialize: (options) ->
            super
            @initializeProperties(options)
            @initializeAction(options)

        initializeProperties: (options) ->
            @setPropertyFromOptions(options, 'sidebarTimeline', required: true)

        initializeAction: (options) ->
            if @sidebarTimeline.getRootTimeline()?
                @initializeActionForPlantPlayer(options)
            else
                @initializeActionForActivityPlayer(options)

        initializeActionForPlantPlayer: (options) ->
            @action = new @actionClass
                controller: @controller
                sidebarTimeline: @sidebarTimeline

        initializeActionForActivityPlayer: (options) ->
            @action = new GoToActivityList
                controller: @controller
                sidebarTimeline: @sidebarTimeline
                startPosition: 0

        getRenderContext: ->
            ctx = super
            ctx.url = @model.get('titlePageImageUrl')
            ctx

        render: ->
            return unless @model.get('titlePageImageUrl')
            super
            disableSelection(@el)

        onPlantTitleImageChange: ->
            @render()

        onClick: (event) ->
            event.preventDefault()
            if @action.isAvailable()
                @action.fullPerform()


    class SidebarView extends RenderableView
        template: template('./common/sidebars/base.ejs')
        className: 'sidebar'
        tilesViewClass: SidebarTilesView
        titlePageImageViewClass: TitlePageImageView
        events:
            'jsp-scroll-y .sidebar__tiles-container': 'onScrollChange'


        initialize: (options) ->
            model = options.sidebarTimeline.sidebarState
            subviewsOptions = _.clone(options)
            options = _.clone(options)
            options.model = model
            options.subviews ?= {}
            _.extend(options.subviews, @getSidebarSubviews(subviewsOptions))
            super(options)
            @setOption(options, 'sidebarTimeline', null, true)

        getRenderContext: ->
            ctx = super
            ctx.backURL = @controller.backURL
            ctx

        getSidebarSubviews: (options) ->
            model = options.sidebarTimeline.sidebarState
            tilesOptions = _.clone(options)
            tilesOptions.collection = model.getChapters()
            @tilesView = new @tilesViewClass(tilesOptions)

            titlePageImageOptions = _.clone(options)
            titlePageImageOptions.model = model
            @titlePageImageView = new @titlePageImageViewClass(titlePageImageOptions)

            '.sidebar__tiles': @tilesView
            '.sidebar__title-page-image': @titlePageImageView

        remove: ->
            @tilesView.remove()
            super

        renderTemplate: ->
            super
            @$tilesContainerEl = @$('.sidebar__tiles-container')
            @reinitializeScroll()

        reinitializeScroll: ->
            scrollOffset = @model.get('scrollOffset')
            jsp = @$tilesContainerEl.data('jsp')
            if jsp?
                jsp.reinitialise()
            else
                @$tilesContainerEl.jScrollPane(dragOffset: 4)
                jsp = @$tilesContainerEl.data('jsp')
            jsp.scrollToY(scrollOffset)

        updateScrollScale: (scale) ->
            jsp = @$tilesContainerEl.data('jsp')
            jsp.setScaleRatio(scale) if jsp?

        renderAllSubviews: ->
            super
            @reinitializeScroll()

        renderCore: ->
            @renderTemplate()
            @renderAllSubviews()
            @rendered = true

        onParentViewBind: ->
            @listenTo(@parentView, 'change:pageContainerScale',
                (pageView, scale) => @updateScrollScale(scale)
            )

        onModelBind: ->
            super
            @listenTo(@model, 'change:activeChapterIndex',
                      @onModelActiveChapterIndexChange)

        onModelActiveChapterIndexChange: -> @invalidate()

        onScrollChange: (event, scrollPositionY) ->
            @model.set('scrollOffset', scrollPositionY, silent: true)


    module.exports =
        TileElementView: TileElementView
        TileElementsView: TileElementsView
        SidebarTileView: SidebarTileView
        SidebarTilesView: SidebarTilesView
        TitlePageImageView: TitlePageImageView
        SidebarView: SidebarView
