    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {template} = require('./../../../../common/templates')
    {BaseView} = require('./../../../../common/views/base')
    {RenderableView} = require('./../../../../common/views/renderable')
    {MediaLibraryPanelBase} = require('./base')


    ## MEDIALIBRARY SEARCH VIEWS ##
    class MediaSearchInput extends BaseView

        tagName: "input"
        className: "search-query media-library-search-query"

        attributes:
            type: "text"
            placeholder: "Search"

        events:
            'keyup': 'onKeyup'

        onKeyup: (ev) =>
            newText = @getText()
            if @lastText == newText
                return
            @lastText = newText
            @trigger('change:query', @, newText)

        initialize: (options) =>
            super
            @panel = options.panel
            @

        getText: => @$el.val()

        show: => @$el.show()

        hide: => @$el.hide()


    class SearchPanelItem extends RenderableView
        template: template('./editor/media/library/search_item.ejs')

        tagName: 'tr'
        className: "media-search-item"

        events: =>
            if @model?
                'click': 'onFileSelected'

        id: => "media_search_item_#{@model?.cid or 'missing'}"

        initialize: (options) ->
            super
            @model = options.model

        onFileSelected: => @trigger('selected', @, @model)


    class SearchPanel extends MediaLibraryPanelBase
        title: 'Search'
        menuName: 'Media library'
        modalTitle: 'Media library'
        template: template('./editor/media/library/search.ejs')
        itemContainerSelector: '.media-search-results'
        itemViewClass: SearchPanelItem

        events:
            'click .pagination-next': 'onPaginationNext'
            'click .pagination-prev': 'onPaginationPrev'

        initialize: (options) =>
            super
            @subviews = {}
            @collection = @parent.mediumMetaCollection
            @listenTo(@collection, 'reset:success', @onFetchComplete)
            @listenTo(@collection, 'reset:error', @onFetchComplete)
            @listenTo(@collection, 'reset:begin', @onFetchBegin)
            @recoveringFromMissingPage = false

        onQueryChange: (sender, query) =>
            @collection.search(query?.toLowerCase() or '')

        createItemView: (model) =>
            item = new @itemViewClass
                model: model
            @listenTo(item, 'selected', @onItemSelected)
            item

        removeSubviews: =>
            for view in @subviews[@itemContainerSelector] or []
                @stopListening(view)
                view.remove()
            delete @subviews[@itemContainerSelector]

        getCollectionViews: =>
            if @collection.length == 0
                [@createItemView()]
            else
                @collection.map @createItemView

        getLoader: =>
            @_loader ?= $('<div>')
                .addClass('progress progress-striped active')
                .html(
                    $('<div>')
                        .addClass('bar')
                        .css(width: '100%')
                )
            @_loader.css(display: 'none')
            @_loader

        onFetchBegin: =>
            # show a loader
            @$(@itemContainerSelector).html(@getLoader())
            @getLoader().show(100)

        onFetchComplete: =>
            # Handling the case when we get an empty page while it's not the
            # first page of search. Try to get previous page or reset search.
            if @collection.page > 0 and @collection.length == 0
                if @recoveringFromMissingPage
                    @recoveringFromMissingPage = false
                    @collection.search(@collection.query)
                else
                    @recoveringFromMissingPage = true
                    @collection.prevPage()
                return
            @recoveringFromMissingPage = false

            # reset all views
            itemViews = @getCollectionViews()
            @removeSubviews()
            @subviews[@itemContainerSelector] = itemViews

            # prevent re-rendering when the view was not yet rendered
            @render() if _.result(this, 'isRendered')

        remove: =>
            @removeSubview(@navView)
            @removeSubview(@searchInputView)

            @stopListening(@collection)
            delete @collection

            delete @_loader
            super

        getNavViews: =>
            super
            if not @searchInputView?
                @searchInputView = new MediaSearchInput
                    panel: @
                @listenTo(@searchInputView, 'change:query', @onQueryChange)
            @navViews = [@searchInputView, @navView]

        show: =>
            super
            @delegateEvents()
            @searchInputView?.show()
            @navView.hide()

        hide: =>
            super
            @searchInputView?.hide()
            @navView.show()

        render: =>
            # check if should fetch initial data
            fetch = not _.result(this, 'isRendered') and @collection.length == 0
            super
            @collection.fetch() if fetch
            @

        isOKAllowed: => false

        onPaginationNext: => @collection.nextPage()

        onPaginationPrev: => @collection.prevPage()

        onItemSelected: (view, mediaMetaModel) =>

        finishItemSelection: ->


    class CloseOnSelectSearchPanel extends SearchPanel

        onItemSelected: (view, mediaMetaModel) =>
            @model.set(url: mediaMetaModel.get('url'))
            @editor.model.addMedium(@model)
            @finishItemSelection()

        finishItemSelection: ->
            @parent.hide()


    class EditSearchPanel extends SearchPanel

        onItemSelected: (view, mediaMetaModel) =>
            @setModelAttribute('url', mediaMetaModel.get('url'))
            @finishItemSelection()

        finishItemSelection: -> @parent.openDefaultPanel()


    class EventedSearchPanel extends SearchPanel

        onItemSelected: (view, mediaMetaModel) =>
            @setModelAttribute('url', mediaMetaModel.get('url'))
            @finishItemSelection()

        finishItemSelection: -> @trigger('itemselected', @)


    module.exports =
        SearchPanel: SearchPanel
        EditSearchPanel: EditSearchPanel
        SearchPanelItem: SearchPanelItem
        CloseOnSelectSearchPanel: CloseOnSelectSearchPanel
        EventedSearchPanel: EventedSearchPanel
