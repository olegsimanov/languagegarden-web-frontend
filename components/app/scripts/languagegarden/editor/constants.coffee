    'use strict'

    _ = require('underscore')

    class TextSize
        @TINY = 'tiny'
        @SMALL = 'small'
        @NORMAL = 'normal'
        @BIG = 'big'
        @HUGE = 'huge'
        @DEFAULT = @NORMAL

        @DISPLAY_NAMES = {}
        @DISPLAY_NAMES[@TINY] = 'Tiny'
        @DISPLAY_NAMES[@SMALL] = 'Small'
        @DISPLAY_NAMES[@NORMAL] = 'Normal'
        @DISPLAY_NAMES[@BIG] = 'Big'
        @DISPLAY_NAMES[@HUGE] = 'Huge'


    class MediumType
        @TEXT = 'text'
        @TEXT_TO_PLANT = 'text-to-plant'

    class VisibilityType
        @VISIBLE = 'visible'
        @HIDDEN = 'hidden'
        @PLANT_TO_TEXT_FADED = 'plant-to-text-faded'
        @FADED = 'faded'

        @DEFAULT = @VISIBLE

    class PlacementType
        @CANVAS = 'canvas'
        @UNDERSOIL = 'undersoil'
        @HIDDEN = 'hidden'


    class CanvasLayers
        @BACKGROUND = 'background'
        @SELECTION_RECT = 'selectionRect'
        @LETTERS = 'letters'
        @LETTER_AREAS = 'letterAreas'

    class CanvasMode
        @MOVE = 'move'
        @PLANT_TO_TEXT = 'plant to text'

        @DEFAULT = @MOVE

    visibilityOpacityMap = {}
    visibilityOpacityMap[VisibilityType.VISIBLE] = 1.0
    visibilityOpacityMap[VisibilityType.HIDDEN] = 0.0
    visibilityOpacityMap[VisibilityType.PLANT_TO_TEXT_FADED] = 0.25
    visibilityOpacityMap[VisibilityType.FADED] = 0.5


    markedOpacityMap = {}
    markedOpacityMap[true] = 1.0
    markedOpacityMap[false] = 0.25

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
        EditorLayers: CanvasLayers          # TODO: please remove this duplication
        CanvasLayers: CanvasLayers          # TODO: please remove this duplication
        TextSize: TextSize
        MediumType: MediumType
        VisibilityType: VisibilityType
        PlacementType: PlacementType
