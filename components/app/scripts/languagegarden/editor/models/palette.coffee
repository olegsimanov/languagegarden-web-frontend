    'use strict'

    {Palette, ToolCollection} = require('./../../common/models/palette')
    {ColorMode} = require('./../constants')


    ###Handles selection of tools - ensures there is only a single tool
    selected at a time.
    ###
    class EditorToolCollection extends ToolCollection

        initialize: (options) =>
            super
            @listenTo(@, 'change:selected', @onToolSelectedChange)

        cleanup: =>
            @stopListening(@)

        onToolSelectedChange: (sender, isSelected) =>
            if isSelected
                @each (tool) ->
                    if tool != sender and tool.get('selected')
                        tool.set('selected', false)


    class EditorPalette extends Palette

        toolCollectionClass: EditorToolCollection

        initialize: (options) =>
            super

            @set('colorMode', options.colorMode or ColorMode.DEFAULT)
            @set('newWordColor', options.newWordColor)

            selectedTool = options.selectedTool or @tools.first()
            @set('selectedTool', selectedTool)
            @tools.each((t) -> t.set('selected', t == selectedTool))

            @listenTo(@, 'selectedTool', @onSelectedToolChange)
            @listenTo(@tools, 'change:selected', @onToolSelectedChange)

        remove: =>
            @stopListening(@tools)
            @stopListening(@)
            super

        ###Tool was selected by setting @selectedTool.###
        onSelectedToolChange: (sender, selectedTool, options) =>
            selectedTool.set('selected', true)

        ###Tool was selected by setting tool.set('selected', true) or
        deselected by the collection.
        ###
        onToolSelectedChange: (sender, isSelected, options) =>
            @set('selectedTool', sender) if isSelected


    module.exports =
        EditorPalette: EditorPalette
