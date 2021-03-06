    'use strict'

    _ = require('underscore')

    class MediumType

        @TEXT                   = 'text'
        @TEXT_TO_CANVAS         = 'text-to-canvas'

    class VisibilityType

        @VISIBLE                = 'visible'
        @HIDDEN                 = 'hidden'
        @FADED                  = 'faded'

        @DEFAULT                = @VISIBLE

    class PlacementType

        @CANVAS                 = 'canvas'
        @UNDERSOIL              = 'undersoil'
        @HIDDEN                 = 'hidden'


    class CanvasLayers

        @BACKGROUND             = 'background'
        @SELECTION_RECT         = 'selectionRect'
        @LETTERS                = 'letters'
        @LETTER_AREAS           = 'letterAreas'


    visibilityOpacityMap                            = {}
    visibilityOpacityMap[VisibilityType.VISIBLE]    = 1.0
    visibilityOpacityMap[VisibilityType.HIDDEN]     = 0.0
    visibilityOpacityMap[VisibilityType.FADED]      = 0.5


    markedOpacityMap        = {}
    markedOpacityMap[true]  = 1.0
    markedOpacityMap[false] = 0.25

    ColorMode =
        DEFAULT:    'word'
        WORD:       'word'
        LETTER:     'letter'

    class CanvasMode

        @MOVE               = 'move'
        @STRETCH            = 'stretch'
        @SCALE              = 'scale'
        @GROUP_SCALE        = 'group scale'
        @EDIT               = 'edit'
        @COLOR              = 'color'
        @TEXT_EDIT          = 'text edit'
        @ROTATE             = 'rotate'

    ToolbarEnum =
        NAVIGATION:     'navigation'
        BUILDER:        'builder'
        COLOR:          'color'


    module.exports =

        ToolbarEnum:        ToolbarEnum
        ColorMode:          ColorMode
        CanvasMode:         CanvasMode
        CanvasLayers:       CanvasLayers
        MediumType:         MediumType
        VisibilityType:     VisibilityType
        PlacementType:      PlacementType
