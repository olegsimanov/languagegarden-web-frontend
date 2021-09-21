    'use strict'

    require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    {isDarkColor} = require('./../../common/utils')
    {
        disableSelection
        getOffsetRect
        addSVGElementClass
    } = require('./../../common/domutils')
    {LetterMetrics} = require('./../../common/svgmetrics')
    {
        ColorAction
        RemoveColorAction
        SplitColorAction
    } = require('./../actions/color')
    {NoteView} = require('./../../common/views/media/note')
    {EditorDummyMediumView} = require('./media/base')
    {EditorImageView} = require('./media/images')
    {EditorNoteView} = require('./media/note')
    {EditorPlantLinkView} = require('./media/links')
    {EditorElementView, EditedElementView} = require('./elements')
    {ElementView} = require('./../../common/views/elements')
    {MoveBehavior, MediaMoveBehavior} = require('./../modebehaviors/move')
    {ColorBehavior} = require('./../modebehaviors/color')
    {StretchBehavior} = require('./../modebehaviors/stretch')
    {ScaleBehavior} = require('./../modebehaviors/scale')
    {GroupScaleBehavior} = require('./../modebehaviors/groupscale')
    {EditBehavior} = require('./../modebehaviors/edit')
    {TextEditBehavior} = require('./../modebehaviors/textedit')
    {PlantToTextBehavior} = require('./../modebehaviors/planttotext')
    {RotateBehavior} = require('./../modebehaviors/rotate')
    {
        MarkBehavior
    } = require('./../../common/modebehaviors/mark')
    {EditorMode, EditorLayers, ColorMode} = require('./../constants')
    {interpolateColor} = require('./../../common/interpolations/colors')
    {interpolateValue} = require('./../../common/interpolations/base')
    {OperationType} = require('./../../common/diffs/operations')
    {splitDiff} = require('./../../common/diffs/utils')
    {Point} = require('./../../math/points')
    {BBox} = require('./../../math/bboxes')
    {PlantElement} = require('./../../common/models/elements')
    {
        PlacementType
    } = require('./../../common/constants')
    {CanvasView} = require('./../../common/views/canvas')
    {backgroundColorChoices} = require('./../colors')


    class BaseEditorCanvasView extends CanvasView
        className: "#{CanvasView::className} editor"

        initialize: (options) ->
            super
            @insertView = null

            # editor fields initial values
            @dragged = false
            @dragging = false
            @bgDragging = false
            @initializeBackgroundColors()

            # listening on own events
            @listenTo(this, 'selectchange', @onSelectChange)
            @listenTo(this, 'change:dragging', (s, v) => @toggleDraggingClass(v))
            @listenTo(this, 'change:bgDragging', (s, v) => @toggleBgDraggingClass(v))
            @listenTo(this, 'change:mode', @onModeChange)

            @initializeSelectionRect()
            @initializeEditorEl()

        getPlantEditorModeConfig: ->
            startMode: EditorMode.MOVE
            modeSpecs: [
                mode: EditorMode.MOVE
                behaviorClass: MoveBehavior
            ,
                mode: EditorMode.COLOR
                behaviorClass: ColorBehavior
            ,
                mode: EditorMode.STRETCH
                behaviorClass: StretchBehavior
            ,
                mode: EditorMode.SCALE
                behaviorClass: ScaleBehavior
            ,
                mode: EditorMode.GROUP_SCALE
                behaviorClass: GroupScaleBehavior
            ,
                mode: EditorMode.ROTATE
                behaviorClass: RotateBehavior
            ,
                mode: EditorMode.EDIT
                behaviorClass: EditBehavior
            ,
                mode: EditorMode.TEXT_EDIT
                behaviorClass: TextEditBehavior
            ,
                mode: EditorMode.PLANT_TO_TEXT
                behaviorClass: PlantToTextBehavior
            ]

        getModeConfig: ->
            @getPlantEditorModeConfig()


        settingsKey: -> "editor-#{super}"

        initializeSelectionRect: =>
            # initial Raphael objects
            @selectionRectObj = @paper.rect(0, 0, 1, 1)
            addSVGElementClass(@selectionRectObj.node, 'selection-area')
            disableSelection(@selectionRectObj.node)
            @selectionRectObj.hide()
            @putElementToFrontAtLayer(@selectionRectObj,
                                      EditorLayers.SELECTION_RECT)

        initializeEditorEl: =>
            @toggleModeClass()
            @toggleDraggingClass(false)
            @toggleBgDraggingClass(false)

        initializeBackgroundColors: =>
            @bgColorChoices = _.clone(backgroundColorChoices)

        remove: =>
            @selectionRectObj.remove()
            @stopListening(this)
            @stopListening(@model)
            super

        ###
        Editor Fields interface
        ###

        getPaletteToolAction: (toolModel) =>
            toolModel ?= @colorPalette.get('selectedTool')
            switch toolModel.type
                when 'color' then actionCls = ColorAction
                when 'splitcolor' then actionCls = SplitColorAction
                when 'removecolor' then actionCls = RemoveColorAction

            if actionCls?
                new actionCls
                    controller: @controller
                    toolModel: toolModel

        getCaretColor: (color) =>
            color ?= @model.get('bgColor')
            if isDarkColor(color) then '#000000' else '#FFFFFF'

        toggleModeClass: (mode=@mode, flag=true) =>
            @$el.toggleClass("#{mode.replace(/\s/g,'-')}-mode", flag)

        toggleDraggingClass: (flag=true) =>
            @$el.toggleClass("in-dragging", flag)

        toggleBgDraggingClass: (flag=true) =>
            @$el.toggleClass("in-bg-dragging", flag)

        setDragging: (dragging) => @setField('dragging', dragging)

        setBgDragging: (bgDragging) => @setField('bgDragging', bgDragging)

        ###
        Adding/Removing/Resetting elements helpers
        ###

        getElementViewConstructor: (model) ->
            (options) -> new EditorElementView(options)

        getElementViewConstructorOptions: (model) ->
            model: model
            parentView: this
            editor: this
            paper: @paper

        removeElementView: (model) ->
            view = @elementViews["#{model.cid}"]
            wasSelected = view.isSelected()
            super(model)
            if wasSelected then @selectChange()

        ###
        Adding/Removing/Resetting media helpers
        ###

        getMediumViewClass: (model) ->
            if model.get('placementType') == PlacementType.HIDDEN
                null
            else
                super
        getMediumViewConstructor: (model) ->
            viewCls = @getMediumViewClass(model) or EditorDummyMediumView
            (options) -> new viewCls(options)

        getMediumViewConstructorOptions: (model) ->
            options = super
            options.editor = this
            options

        removeMediumView: (model) ->
            view = @mediaViews["#{model.cid}"]
            wasSelected = view.isSelected()
            super(model)
            if wasSelected then @selectChange()


        ###
        Event handlers
        ###

        onModeChange: =>

        restoreDefaultMode: =>
            @deselectAll()
            @setDefaultMode()

        onSelectChange: =>
            $el = $(@el)
            numOfElemSelections = @getSelectedElements().length
            selectedMediaViews = @getSelectedMediaViews()
            numOfMediaSelections = selectedMediaViews.length
            numOfSelections = @getSelectedViews().length

            useIfAvailable = (mode) =>
                if @isModeAvailable(mode)
                    return mode
                else
                    return @defaultMode

            if numOfSelections > 0
                $el.addClass('selections-present')
            else
                $el.removeClass('selections-present')

            if numOfSelections > 1
                $el.addClass('multi-select')
            else
                $el.removeClass('multi-select')

            if numOfSelections > 0
                @colorPalette.set('colorMode', ColorMode.WORD)

            if @mode == EditorMode.EDIT
                # the selection was made during edition, which means it
                # wasn't caused by user. therefore we skip the
                # mode switching part
                return

            if @mode == EditorMode.COLOR
                # we don't want to switch mode if selection was made when
                # color mode was active
                return

            # WARNING: only switch to mode behaviors which do NOT change the
            # selection when handling 'modeenter' event. In other case there
            # will be an infinite event loop
            mode = @defaultMode
            if numOfSelections == 1
                if numOfElemSelections == 1
                    if @getSelectedElements()[0].get('text').length == 1
                        # one letter word - selecting SCALE mode by default as
                        # it is the only mode available for such words
                        mode = useIfAvailable(EditorMode.SCALE)
                    else
                        mode = useIfAvailable(EditorMode.STRETCH)
                else if numOfMediaSelections == 1
                    switch selectedMediaViews[0]?.model.get('type')
                        when MediumType.IMAGE
                            mode = useIfAvailable(EditorMode.IMAGE_EDIT)
            @setMode(mode)
            @selectionBBoxChange()

        onMediumViewPlaybackChange: (player, view) =>
            if view? and view.editor == this and view.isSelected()
                @trigger('selectionplaybackchange', player, view)

        onDocumentKeyUp: (event) =>
            code = if event.keyCode then event.keyCode else event.which
            switch code
                when 17 then @multiSelect = false

        onDocumentKeyDown: (event) =>
            code = if event.keyCode then event.keyCode else event.which
            switch code
                when 17 then @multiSelect = true

        ###
        Element edition interface
        ###

        startInserting: (p) =>
            insertModel = new PlantElement
                startPoint: p
                text: ''
                fontSize: @settings.get('fontSize')
            @editElementModelPosition = null
            @startEditing(insertModel)

        startUpdating: (elemModel) =>
            # we disable tracking because we temporarily remove the model
            @model.stopTrackingChanges()
            @editElementModelPosition = @model.elements.indexOf(elemModel)
            @model.removeElement(elemModel)
            @startEditing(elemModel)

        startEditing: (elemModel) =>
            # we use reload=true to finish previous edit, if present
            @setMode(EditorMode.EDIT, true)
            @insertView = new EditedElementView
                paper: @paper
                editor: this
                model: elemModel
            @insertView.render()

        finishEditing: (options) =>
            @setDefaultMode()

        # Media

        # click-to-edit text box
        startTextEditing: (textView) =>
            textView.shouldEnterEditMode = true
            @setMode(EditorMode.TEXT_EDIT, true)

        finishTextEditing: (textView) => @setDefaultMode()

        # plant-to-text note
        startPlantToTextMode: (plantToTextModel) ->
            @activePlantToTextObjectId = plantToTextModel.get('objectId')
            @setMode(EditorMode.PLANT_TO_TEXT)

        finishPlantToTextMode: -> @setDefaultMode()

        getActivePlantToTextView: ->
            if not @activePlantToTextObjectId?
                return null
            mediaViews = @getMediaViews()
            for view in mediaViews
                if view.model.get('objectId') == @activePlantToTextObjectId
                    return view
            return null

        ###
        Element views helper functions
        ###

        getSelectableViews: =>
            @getElementViews().concat(@getMediaViews())

        ###
        Selection interface
        ###

        selectChange: => @trigger('selectchange')

        deselectAll: (options) =>
            anySelected = false
            processView = (view) =>
                if view.isSelected()
                    anySelected = true
                    view.select(false, silent: true)
            for name, view of @elementViews
                processView(view)
            for name, view of @mediaViews
                processView(view)
            if options?.silent
                return
            if anySelected
                @trigger('selectchange')

        reselect: (views, options) =>
            selectionChanged = false
            processView = (view) =>
                if view in views
                    if not view.isSelected()
                        selectionChanged = true
                        view.select(true, silent: true)
                else
                    if view.isSelected()
                        selectionChanged = true
                        view.select(false, silent: true)
            for name, view of @elementViews
                processView(view)
            for name, view of @mediaViews
                processView(view)
            if options?.silent
                return
            if selectionChanged
                @trigger('selectchange')

        getElementViewByModelCid: (cid) =>
            _.find @elementViews, (v) -> v?.model?.cid == cid

        getElementByCid: (cid) => @getElementViewByModelCid(cid)?.model

        getSelectedElements: =>
            view.model for name, view of @elementViews when view.isSelected()

        getSelectedElementViews: =>
            view for name, view of @elementViews when view.isSelected()

        getSelectedMedia: =>
            view.model for name, view of @mediaViews when view.isSelected()

        getSelectedMediaViews: =>
            view for name, view of @mediaViews when view.isSelected()

        getSelectedViews: =>
            @getSelectedElementViews()
            .concat(@getSelectedMediaViews())

        selectionBBoxChange: => @trigger('change:selectionBBox')

        getSelectionBBox: =>
            bboxes = (view.getBBox() for view in @getSelectedViews())
            bboxes.push(@insertView.getBBox()) if @insertView?.isSelected()
            BBox.fromBBoxList(bboxes)


        ###
        Letter areas
        ###

        updateDirtyLetterAreas: =>
            for view in @getElementViews()
                if view.letterAreasDirty
                    view.updateLetterAreas()

        rewindModel: (position) ->
            if not @model.canRewind()
                return

            @deselectAll()

        rewindModelNext: ->
            if @model.hasNextPosition()
                @rewindModel(@model.getDiffPosition() + 1)

        rewindModelPrev: ->
            if @model.hasPrevPosition()
                @rewindModel(@model.getDiffPosition() - 1)

        rebaseModelDiffs: ->

        deletePreviousModelDiff: ->

        toggleKeyFrame: ->


    class EditorCanvasView extends BaseEditorCanvasView


    class NavigatorCanvasView extends BaseEditorCanvasView

        getNavigatorModeConfig: ->
            startMode: EditorMode.NOOP
            defaultMode: EditorMode.NOOP
            modeSpecs: []

        getModeConfig: -> @getNavigatorModeConfig()

        getMediumViewClass: (model) ->
            if model.get('placementType') == PlacementType.HIDDEN
                null
            else
                switch model.get('type')
                    when MediumType.DICTIONARY_NOTE then NoteView
                    else super


    module.exports =
        EditorCanvasView: EditorCanvasView
        NavigatorCanvasView: NavigatorCanvasView
