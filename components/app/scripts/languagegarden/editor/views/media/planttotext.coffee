    'use strict'

    _ = require('underscore')
    {deepCopy, structuralEquals} = require('./../../../common/utils')
    {EditorMode} = require('./../../constants')
    {
        PlacementType
        visibilityOpacityMap
    } = require('./../../../common/constants')
    {PlantToTextBehavior} = require('./../../modebehaviors/planttotext')
    {
        HtmlMediumView
        VisibilityPrototype
        HTMLStylablePrototype
    } = require('./../../../common/views/media/base')


    EditorPlantToTextNoteInterface = HtmlMediumView
        .extend(VisibilityPrototype)
        .extend(HTMLStylablePrototype)

    ###Overrides certain defaults that are set by base classes.###
    EditorPlantToTextNoteBase = class extends EditorPlantToTextNoteInterface

        initialize: (options) ->
            super
            @listenTo(@model, 'change:visibilityType', @updateVisibility)

        # SelectablePrototype/EventDispatchingPrototype
        getClickableNode: -> @getElementNode()

        getElementNode: -> @$el.get(0)

        updateText: -> @$el.html(@getTextContent())

        render: ->
            @updateText()
            @setPosition()
            @updateVisibility?()
            @appendToContainerIfNeeded()
            this

    ###Specialized note that adds the plant to text interaction.

    Typing in this type of note is prohibited, text can only be entered using
    the PLANT_TO_TEXT interaction described below.

    There is a modebehavior tightly paired with this view, see:
        languagegarden.editor.modebehaviors.planttotext.PlantToTextBehavior

    Plant to text interaction involves the following steps:
    1) click on a PLANT_TO_TEXT note to activate it
    2) PLANT_TO_TEXT mode is triggered
    3) plant elements on the canvas become faded down (visibilityType change)
    4) clicking a plant element will make the plant fade up and word appear in
    the note
    5) note avails an array of tools for manipulating words it contains:
    removal, case change, word merging (operated by tooltip actions)
    6) leaving the PLANT_TO_TEXT mode will return elements to their original
    state
    7) when a note with some words input enters the PLANT_TO_TEXT mode, only the
    unselected plant elements will be faded down.

    Notes:
    At a time, only a single note of this type can be selected, all others are
    faded down (again handled by visibilityType).

    When an element is selected more than once it should blink briefly to
    indicate that a selection was made. In editor it's don by simple timeout.

    This note stores a number of attributes in the model:
    * inPlantToTextMode - to denote the current active PLANT_TO_TEXT note
    * noteTextContent - model id's to keep the link between text and plant
    elements along with the copy of actual text content (should the model be
    removed before note is) see this.addElementView for more details.

    ###
    EditorPlantToTextNote = class extends EditorPlantToTextNoteBase

        className: "plant-to-text-box"

        # VISUALS
        reselectBlinkTime: 200

        setPosition: (x, y) ->

        getPlacementType: -> PlacementType.UNDERSOIL

        # PLUGGING IN
        initialize: =>
            super
            @listenTo(@model, 'change:noteTextContent', @onTextContentChanged)

        render: =>
            super
            @$el.toggleClass('in-plant-to-text-mode', @isInPlantToTextMode())
            @

        getElementViews: ->
            @parentView.controller.canvasView.getElementViews() or []

        onTextContentChanged: =>
            views = @getContentElementViews()
            for view in @getElementViews()
                isPlantToTextChosen = view in views
                view.setVisibilityType(
                    PlantToTextBehavior.getVisibilityType(isPlantToTextChosen))

            @updateText()
            @render()

        ###Returns objectIds of element views added to this note.###
        getContentElementIDs: -> @model.getContentElementIDs()

        ###Returns plant element views added to this note.###
        getContentElementViews: ->
            @getElementViewsForObjectIds(@getContentElementIDs())

        ###Returns plant element views for ids provided.###
        getElementViewsForObjectIds: (ids) ->
            views = []
            for view in @getElementViews()
                if view.model.get('objectId') in ids
                    views.push(view)
            views

        ###Combine the text of selected elements views into own text.###
        getTextContent: -> @model.getTextContent()

        isInPlantToTextMode: => @model.isInPlantToTextMode()

        ###Used when in editor - handles blinking on element re-select using
        simple delay and direct visibility manipulation (omitting the model).
        ###
        blinkElementView: (elementView) =>
            vizType = PlantToTextBehavior.getVisibilityType(false)
            elementView.setCoreOpacity(visibilityOpacityMap[vizType])
            _.delay(
                (->
                    vizType = PlantToTextBehavior.getVisibilityType(true)
                    elementView.setCoreOpacity(visibilityOpacityMap[vizType])
                ), @reselectBlinkTime
            )

    module.exports =
        EditorPlantToTextNote: EditorPlantToTextNote
