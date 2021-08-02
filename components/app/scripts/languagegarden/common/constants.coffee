    'use strict'

    _ = require('underscore')


    class TextSize
        @TINY = 'tiny'
        @SMALL = 'small'
        @NORMAL = 'normal'
        @BIG = 'big'
        @HUGE = 'huge'
        @DEFAULT = @NORMAL

        @NOTE_SIZES = [
            @TINY,
            @SMALL,
            @NORMAL,
            @BIG,
            @HUGE,
        ]

        @DISPLAY_NAMES = {}
        @DISPLAY_NAMES[@TINY] = 'Tiny'
        @DISPLAY_NAMES[@SMALL] = 'Small'
        @DISPLAY_NAMES[@NORMAL] = 'Normal'
        @DISPLAY_NAMES[@BIG] = 'Big'
        @DISPLAY_NAMES[@HUGE] = 'Huge'


    class MediumType
        @IMAGE = 'image'
        @SOUND = 'sound'
        @TEXT = 'text'
        @TEXT_TO_PLANT = 'text-to-plant'
        @PLANT_LINK = 'plant-link'
        @NOTE = 'note' # note medium backwards compatibility
        @DICTIONARY_NOTE = 'dictionary-note'
        @TEXT_TO_PLANT_NOTE = 'text-to-plant-note'
        @PLANT_TO_TEXT_NOTE = 'plant-to-text-note'
        @INSTRUCTIONS_NOTE = 'instructions-note'


        @NOTE_TYPES = [
            @NOTE # note medium backwards compatibility
            @DICTIONARY_NOTE
            @TEXT_TO_PLANT_NOTE
            @PLANT_TO_TEXT_NOTE
            @INSTRUCTIONS_NOTE
        ]
        @TEXT_TYPES = [
            @TEXT
            @NOTE_TYPES...
        ]


    class VisibilityType
        @VISIBLE = 'visible'
        @HIDDEN = 'hidden'
        @PLANT_TO_TEXT_FADED = 'plant-to-text-faded'
        @FADED = 'faded'

        @DEFAULT = @VISIBLE


    class ActivityType
        @PLANT_TO_TEXT = 'plant-to-text'
        @PLANT_TO_TEXT_MEMO = 'plant-to-text-memo'
        @CLICK = 'click'
        @MEDIA = 'media'
        @DICTIONARY = 'dictionary'
        @MOVIE = 'movie'


    class PlacementType
        @CANVAS = 'canvas'
        @UNDERSOIL = 'undersoil'
        @HIDDEN = 'hidden'


    class CanvasLayers
        @BACKGROUND = 'background'
        @SELECTION_RECT = 'selectionRect'
        @IMAGES = 'images'
        @IMAGE_AREAS = 'imageAreas'
        @LETTERS = 'letters'
        @LETTER_AREAS = 'letterAreas'

        #TODO: these are probably unused, remove them
        @SELECTION_TOOLTIP = 'selectionTooltip'
        @MENU = 'menu'


    class CanvasMode
        @NOOP = 'noop'
        @MOVE = 'move'
        @PLANT_TO_TEXT = 'plant to text'

        @DEFAULT = @MOVE


    class PunctuationCharacter
        @COMMA            = ','
        @PERIOD           = '.'
        @QUESTION_MARK    = '?'
        @SEMICOLON        = ';'
        @COLON            = ':'
        @EXCLAMATION_MARK = '!'
        @DASH             = '-'
        @QUOTATION_MARK   = '"'

        @CHARACTERS = [
            @COMMA
            @PERIOD
            @QUESTION_MARK
            @SEMICOLON
            @COLON
            @EXCLAMATION_MARK
            @DASH
            @QUOTATION_MARK
        ]


    visibilityOpacityMap = {}
    visibilityOpacityMap[VisibilityType.VISIBLE] = 1.0
    visibilityOpacityMap[VisibilityType.HIDDEN] = 0.0
    visibilityOpacityMap[VisibilityType.PLANT_TO_TEXT_FADED] = 0.25
    visibilityOpacityMap[VisibilityType.FADED] = 0.5


    markedOpacityMap = {}
    markedOpacityMap[true] = 1.0
    markedOpacityMap[false] = 0.25


    module.exports =
        MediumType: MediumType
        TextSize: TextSize
        VisibilityType: VisibilityType
        ActivityType: ActivityType
        PlacementType: PlacementType
        CanvasLayers: CanvasLayers
        CanvasMode: CanvasMode
        PunctuationCharacter: PunctuationCharacter

        visibilityOpacityMap: visibilityOpacityMap
        markedOpacityMap: markedOpacityMap
