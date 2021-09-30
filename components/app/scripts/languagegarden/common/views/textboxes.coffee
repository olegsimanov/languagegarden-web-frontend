    'use strict'

    _ = require('underscore')
    {MediumType, PlacementType} = require('./../../editor/constants')
    {BaseView} = require('./base')
    {DummyMediumView} = require('./../../editor/views/media/base')
    {TextToPlantView} = require('./media/text_to_plant')
    {Point} = require('./../../math/points')


    class TextBoxView extends BaseView

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'dataModel', required: true)
            @setOption(options, 'letterMetrics', null, true)
            @setOption(options, 'settings', null)
            @rendered = false

        onParentViewBind: ->
            eventNames = ("change:pageContainer#{suf}" for suf in ['Transform',
                                            'Scale', 'ShiftX', 'ShiftY'])
            @setupEventForwarding(@parentView, eventNames)

        onModelBind: ->
            super
            @mediaViews = {}
            @reloadAllMediaViews()
            @listenTo(@model, 'change:textDirection',
                      @onModelTextDirectionChange)
            @listenTo(@model.media, 'add', @onMediumAdd)
            @listenTo(@model.media, 'remove', @onMediumRemove)
            @listenTo(@model.media, 'reset', @onMediaReset)
            @listenTo(@model.media, 'change:inPlantToTextMode',
                      @onMediumInPlantToTextModeChanged)

        onModelUnbind: ->
            @stopListening(@model.media)
            @removeAllMediaViews()
            super

        ###
        Adding/Removing/Resetting media helpers
        ###

        areViewsSynced: (viewsDict, collection) ->
            _.isEqual(_.keys(viewsDict or {}), _.pluck(collection.models, 'cid'))

        getMediaViews: (mediaTypes) =>
            views = (view for name, view of @mediaViews)
            if mediaTypes?
                mediaTypes = [mediaTypes] if _.isString(mediaTypes)
                views = _.filter views, (v) ->
                    v?.model?.get('type') in mediaTypes
            views

        getMediumViewClass: (model) ->
            if model.get('placementType') == PlacementType.HIDDEN
                null
            else
                switch model.get('type')
                    when MediumType.TEXT_TO_PLANT
                        TextToPlantView
                    else
                        null

        getMediumViewConstructor: (model) ->
            viewCls = @getMediumViewClass(model) or DummyMediumView
            (options) -> new viewCls(options)

        addMediumView: (model) ->
            constructor = @getMediumViewConstructor(model)
            view = constructor
                model: model
                controller: @controller
                parentView: this

            @mediaViews["#{model.cid}"] = view
            view.render() if @rendered

        removeMediumView: (model) ->
            view = @mediaViews["#{model.cid}"]
            @stopListening(view)
            view.remove()
            delete @mediaViews["#{model.cid}"]

        removeAllMediaViews: ->
            for own cid, view of @mediaViews
                @stopListening(view)
                view.remove()
            @mediaViews = {}

        reloadAllMediaViews: ->
            @removeAllMediaViews()
            for mediumModel in @model.media.models
                @addMediumView(mediumModel)
            return

        syncMediaViews: ->
            if not @areViewsSynced(@mediaViews, @model.media)
                @reloadAllMediaViews()

        hasInstructionsNote: ->
            for medium in @model.media.models
                if medium.get('type') == MediumType.INSTRUCTIONS_NOTE
                    return true
            false

        updateNotesMode: ->
            instructionsMode = @hasInstructionsNote()
            @$el.toggleClass('instructions-mode', instructionsMode)

        updateTextDirection: ->
            @$el.toggleClass('plant-to-text-box__rtl',
                             @dataModel.get('textDirection') == 'rtl')

        ###
        Event handlers
        ###

        onMediumAdd: (model, collection, options) -> @addMediumView(model)

        onMediumRemove: (model, collection, options) -> @removeMediumView(model)

        onMediaReset: (collection, options) -> @reloadAllMediaViews()

        onMediumInPlantToTextModeChanged: ->
            @updateNotesMode()

        onModelTextDirectionChange: ->
            @updateTextDirection()

        ###
        Canvas helpers
        TODO: refactor this duplicated code to base class!
        ###
        addPlantElement: (options) =>
            options = _.clone(options)

            if not options.fontSize?
                options.fontSize = @settings.get('fontSize') or 20

            if not options.endPoint?
                len = @letterMetrics.getTextLength(
                    options.text, options.fontSize)
                options.endPoint = Point.fromValue(options.startPoint)
                    .add(new Point(len, 0))

            if not options.controlPoints?
                options.controlPoints = [
                    Point.getPointBetween(
                        Point.fromValue(options.startPoint),
                        Point.fromValue(options.endPoint))
                ]
            @model.addElement(options)

        getCanvasSetupDimensions: ->
            [@dataModel.get('canvasWidth'), @dataModel.get('canvasHeight')]

        transformToCanvasCoords: (x, y) ->
            @parentView.transformToCanvasCoords(x, y)

        transformToCanvasCoordOffsets: (dx, dy) ->
            @parentView.transformToCanvasCoordOffsets(dx, dy)

        transformToCanvasBBox: (bbox) ->
            @parentView.transformToCanvasBBox(bbox)

        transformCanvasToContainerCoords: (x, y) ->
            @parentView.transformCanvasToContainerCoords(x, y)

        render: ->
            super
            @syncMediaViews()
            @updateNotesMode()
            @updateTextDirection()
            for own name, view of @mediaViews
                view.render()
            @rendered = true
            this


    module.exports =
        TextBoxView: TextBoxView
