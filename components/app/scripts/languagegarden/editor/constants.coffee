    'use strict'

    _ = require('underscore')
    {CanvasLayers, CanvasMode} = require('./../common/constants')


    ColorMode =
        DEFAULT: 'word'
        WORD: 'word'
        LETTER: 'letter'

    class EditorCanvasMode extends CanvasMode
        @STRETCH = 'stretch'
        @SCALE = 'scale'
        @GROUP_SCALE = 'group scale'
        @EDIT = 'edit'
        @COLOR = 'color'
        @TEXT_EDIT = 'text edit'
        @ROTATE = 'rotate'

        @DEFAULT = @MOVE


    EditorLayers =
        BACKGROUND: 'background'
        SELECTION_RECT: 'selectionRect'
        IMAGES: 'images'
        IMAGE_AREAS: 'imageAreas'
        LETTERS: 'letters'
        LETTER_AREAS: 'letterAreas'
        SELECTION_TOOLTIP: 'selectionTooltip'
        MENU: 'menu'


    module.exports =
        ColorMode: ColorMode
        EditorCanvasMode: EditorCanvasMode
        #TODO: remove
        EditorMode: EditorCanvasMode
        EditorLayers: CanvasLayers
