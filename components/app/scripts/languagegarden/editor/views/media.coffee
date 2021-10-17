    'use strict'

    require('raphael')

    _                   = require('underscore')
    jQuery              = require('jquery')
    $                   = require('jquery')

    {PlantChildView}    = require('./base')
    {
        PlacementType
    }                   = require('../constants')
    {BBox}              = require('./../math/bboxes')


    class MediumViewBase extends PlantChildView

        getPlacementType:   -> PlacementType.CANVAS
        toFront:            =>

    class DummyMediumView extends MediumViewBase

    HTMLStylablePrototype =

        addElementCSS: (node, cssCls)       -> $(node).addClass(cssCls)
        removeElementCSS: (node, cssCls)    -> $(node).removeClass(cssCls)

    VisibilityPrototype =

        updateVisibility: ->

            marked = @model.get('marked')
            if marked in [false, true]
                className = if marked then 'marked' else VisibilityType.FADED
            else
                className = @model.get('visibilityType') or VisibilityType.DEFAULT

            elemNode = @getElementNode()
            for own key, value of VisibilityType
                @removeElementCSS(elemNode, value)
            @addElementCSS(elemNode, className)

        setVisibilityType: (value=VisibilityType.VISIBLE, options) -> @model.set('visibilityType', value, options)

    BaseEditorDummyMediumView = DummyMediumView
        .extend(HTMLStylablePrototype)
        .extend(VisibilityPrototype)


    EditorDummyMediumView = class extends BaseEditorDummyMediumView

        select: (selected=true, options)    ->
        isSelected:                                 -> false
        getBBox:                                    => BBox.newEmpty()
        intersects: (bbox)                          => false

    module.exports =
        MediumViewBase:         MediumViewBase
        DummyMediumView:        DummyMediumView
        EditorDummyMediumView:  EditorDummyMediumView
