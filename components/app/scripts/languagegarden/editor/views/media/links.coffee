    'use strict'

    {PlantLinkView} = require('./../../../common/views/media/links')
    {
        SelectablePrototype
        EventDispatchingPrototype
        EventBindingPrototype
    } = require('./base')
    {
        HTMLStylablePrototype
        VisibilityPrototype
    } = require('./../../../common/views/media/base')


    ExtendedPlantLinkView = PlantLinkView
        .extend(SelectablePrototype)
        .extend(HTMLStylablePrototype)
        .extend(EventDispatchingPrototype)
        .extend(EventBindingPrototype)
        .extend(VisibilityPrototype)


    EditorPlantLinkView = class extends ExtendedPlantLinkView

        initialize: (options) ->
            super
            @editor = options.editor or options.parentView
            @bindClickableElementEvents()

        getElementNode: -> @el


    module.exports =
        EditorPlantLinkView: EditorPlantLinkView
