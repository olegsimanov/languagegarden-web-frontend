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


    module.exports =
        ColorMode: ColorMode
        EditorCanvasMode: EditorCanvasMode
        EditorMode: EditorCanvasMode
        EditorLayers: CanvasLayers
