    'use strict'

    _ = require('underscore')
    {buildPropertySupportPrototype} = require('./../properties')
    {BaseView} = require('./base')
    {RenderableView} = require('./renderable')


    CollectionSupportPrototype = buildPropertySupportPrototype('collection')

    ###Mixin for views that need to render view per model in a collection.
    Simplifies management of views for models of the collection.

    ###
    CollectionSubviewMixin =

        itemViewClass: null

        __required_interface_methods__: [
            'appendItemViewToContainer'
            'removeItemViewFromContainer'
        ]

        collectionSubviewMixinSetup: ->
            @listenTo(@collection, 'add', @onCollectionModelAdd)
            @listenTo(@collection, 'remove', @onCollectionModelRemove)
            @listenTo(@collection, 'reset', @onCollectionReset)
            @listenTo(@collection, 'sort', @onCollectionSort)

        collectionSubviewMixinTearDown: ->
            @removeAllItemViewsCore()
            @stopListening(@collection)
            delete @collection

        # ADD / REMOVE

        areViewsSynced: (viewsDict, collection) ->
            _.isEqual(_.keys(viewsDict or {}),
                      collection.map(@getModelID, this))

        getItemViewClass: (model) -> @itemViewClass

        addItemViewCore: (model) ->
            id = @getModelID(model)
            view = @createItemView(model)
            if not view?
                return
            @_itemSubviews ?= {}
            @_itemSubviews[id] = view
            view.setParentView(this)
            view.render() if @rendered
            @appendItemViewToContainer(view)

        removeItemViewCore: (model) ->
            id = @getModelID(model)
            view = @_itemSubviews[id]
            if not view?
                return
            @removeItemViewFromContainer(view)
            delete @_itemSubviews[id]
            view.remove()

        removeAllItemViewsCore: ->
            for view in _.values(@_itemSubviews or {})
                @removeItemViewFromContainer(view)
            @_itemSubviews = {}

        addAllItemViewsCore: ->
            for model in @collection.models
                @addItemViewCore(model)
            return

        syncItemViews: ->
            if not @areViewsSynced(@_itemSubviews, @collection)
                @removeAllItemViewsCore()
                @addAllItemViewsCore()
                true
            else
                false

        getItemView: (model) -> @_itemSubviews[@getModelID(model)]

        getItemContainerViews: ->
            views = []
            # We are using the collection to provide the views in specific
            # order. Because not all views may not been initialized, (e.g first
            # collection add event was fired on collection with multiple
            # elements) we need to check for existence.
            for model in @collection.models
                view = @getItemView(model)
                if view?
                    views.push(view)
            views

        getModelID: (model) -> model.cid

        addItemView: (model) ->
            @trigger('view:addmodel:before', this, model)
            @addItemViewCore(model)
            @trigger('view:addmodel', this, model, @getItemView(model))

        removeItemView: (model) ->
            @trigger('view:removemodel:before', this, model, @getItemView(model))
            @removeItemViewCore(model)
            @trigger('view:removemodel', this, model)

        reloadAllItemViews: ->
            @removeAllItemViewsCore()
            @addAllItemViewsCore()
            @trigger('view:reset', this)

        getItemViewOptions: (model) ->
            controller: @controller
            model: model
            parentView: @

        createItemView: (model) ->
            viewCls = @getItemViewClass(model)
            new viewCls(@getItemViewOptions(model))

        # EVENTS
        onCollectionModelAdd: (model) -> @addItemView(model)

        onCollectionModelRemove: (model) -> @removeItemView(model)

        onCollectionReset: -> @reloadAllItemViews()

        onCollectionSort: -> @reloadAllItemViews()


    RenderableCollectionViewBase = RenderableView
        .extend(CollectionSubviewMixin)

    ###Base class combining RenderableView with CollectionSubviewMixin.###
    RenderableCollectionView = class extends RenderableCollectionViewBase
        itemContainerSelector: ''

        initialize: (options) ->
            super
            @setOptions(options, ['collection'], true)
            @collectionSubviewMixinSetup()

        remove: ->
            @collectionSubviewMixinTearDown()
            @removeAllSubviews()
            super

        appendItemViewToContainer: (view) ->
            @updateItemViews()

        removeItemViewFromContainer: (view) ->
            @removeSubview(view)
            @updateItemViews()

        updateItemViews: ->
            @subviews ?= {}
            @subviews[@itemContainerSelector] = @getItemContainerViews()


    BaseCollectionViewHelper = BaseView
    .extend(CollectionSupportPrototype)
    .extend(CollectionSubviewMixin)


    BaseCollectionView = class extends BaseCollectionViewHelper

        propertyConfig: BaseCollectionViewHelper::propertyConfig.concat([
            name: 'collection'
        ])

        initialize: (options) ->
            super
            @rendered = false

        appendItemViewToContainer: (view) ->
            @$el.append(view.el)

        removeItemViewFromContainer: (view) ->
            view.$el.detach()

        setElement: (element, delegate) ->
            if @rendered
                @removeAllItemViewsCore()
            super
            if @rendered
                @addAllItemViewsCore()
            this

        onCollectionBind: ->
            super
            @collectionSubviewMixinSetup()

        onCollectionUnbind: ->
            @collectionSubviewMixinTearDown()
            super

        render: ->
            @syncItemViews()
            for view in @getItemContainerViews()
                view.render()
            @rendered = true
            super

        invalidate: ->
            if @rendered
                @render()
            this


    module.exports =
        CollectionSubviewMixin: CollectionSubviewMixin
        RenderableCollectionView: RenderableCollectionView
        BaseCollectionView: BaseCollectionView
