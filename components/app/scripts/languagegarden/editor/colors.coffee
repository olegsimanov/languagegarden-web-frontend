    'use strict'

    initialTools = [
        {color: "#2a94d1", label: 'Noun'}
        {color: "#4e6392", label: 'Pronoun'}
        {color: "#f43745", label: 'Verb'}
        {color: "#1fc836", label: 'Adjective'}
        {color: "#f77a13", label: 'Adverb'}
        {color: "#8b8b8b", label: 'Determiner'}
        {color: "#9f55ae", label: 'Preposition'}
        {color: "#b17a39", label: 'Connective'}
        {color: "#0058c2", label: 'Consonant'}
        {color: "#007047", label: 'Digraph Consonant'}
        {color: "#ef3f72", label: 'Vowel'}
        {color: "#ff5433", label: 'Digraph Vowel'}
        {colorTools: ['Verb', 'Adjective', 'Adverb']}
    ]

    blobColors = [
        {color: '3CC2F7', label: 'Subject'}
        {color: 'FBA6BD', label: 'Predicate'}
        {color: 'FFBD1C', label: 'Adverbial'}
        {color: 'DED4A3', label: 'Clause'}
    ]

    colorPalette = [
        "#524640"
        "#FF9A43"
        "#EDDE45"
        "#EDE5E2"

        "#76EDA9"
        "#C9F41A"
        "#F2D21C"
        "#F2AE32"
        "#F11D6C"
        "#C7B421"

        "#87B5EB"
        "#CB7A09"
        "#576C0C"
        "#183F3A"
        "#161E34"
        "#180721"
    ]

    backgroundColorChoices = [
        # light colors
        '#FFFFFF'
        '#BEDBFF'
        '#A8CBDE'
        '#E8D892'
        '#FFF386'
        '#E8A222'
        '#E8C04E'
        '#FC6936'
        '#F13A0E'
        '#2071D7'

        # dark colors
        '#000000'
        '#1B1C11'
        '#231717'
        '#262433'
        '#253652'
        '#3E4B52'
        '#6E8591'
        '#984D25'
        '#6F586C'
        '#0A438A'
    ]

    module.exports =
        newWordColor:           '#332A2E'
        previewPanelWordColor:  '#576C0C'
        initialTools:           initialTools
        blobColors:             blobColors
        colorPalette:           colorPalette
        backgroundColorChoices: backgroundColorChoices
