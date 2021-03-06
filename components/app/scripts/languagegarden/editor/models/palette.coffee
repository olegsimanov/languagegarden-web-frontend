    'use strict'

    _ = require('underscore')
    Backbone                    = require('backbone')
    {ColorMode}             = require('./../constants')
    {BaseCollection}        = require('./collection')


    class Tool extends Backbone.Model

        editable: false

        initialize: (options) =>
            super
            @set('name', options?.name or @name)


    class ColorTool extends Tool

        editable:   true

        name:       'Color'
        type:       'color'

        initialize: (options) =>
            super
            @set('label', options?.label)
            @set('color', options?.color)


    class RemoveColorTool extends Tool

        name: 'Remove Color'
        type: 'removecolor'


    class SplitColorTool extends Tool

        name: 'Split color'
        type: 'splitcolor'

        initialize: (options) =>
            super
            @listenTo(@, 'color:remove', @colorRemoved)
            @listenTo(@, 'color:add', @colorAdded)

            @colorTools = []
            @reset(options?.colorTools)

        remove: =>
            for tool in @colorTools
                @removeTool(tool)
            delete @colorTools
            @stopListening(@)

        colorRemoved: (colorTool) => @stopListening(colorTool) if colorTool?

        colorAdded: (colorTool) =>
            @listenTo(colorTool, 'remove', @removeTool)
            @listenTo(colorTool, 'destroy', @removeTool)
            @listenTo(colorTool, 'change', @onToolChange)

        onToolChange: (colorTool) =>
            @trigger('change:color', @, colorTool)
            @trigger('change', @)

        pushTool: (colorTool) =>
            @colorTools.push(colorTool)
            @trigger('color:add', colorTool)
            @trigger('change')

        removeTool: (colorTool) =>
            oldLen = @colorTools.length
            @colorTools = _.without(@colorTools, colorTool)

            if oldLen != @colorTools.length
                @trigger('color:remove', colorTool)
                @trigger('change')

        popTool: =>
            last = _.last(@colorTools)
            if not last?
                return

            @colorTools = _.initial(@colorTools)

            if @colorTools.indexOf(last) == -1
                @trigger('color:remove', last)
            else
                @trigger('color:pop', last)
            @trigger('change')

        reset: (colorTools=[]) =>
            for tool in @colorTools
                @removeTool(tool)
            for tool in colorTools
                @pushTool(tool)

        getLabels: => _.map @colorTools, (x) -> x.get('label')
        getColors: => _.map @colorTools, (x) -> x.get('color')


    class ToolCollection extends BaseCollection

        model: Tool

        createTools: (toolInfos) =>
            tools = []
            for detail in toolInfos
                action = null
                if detail.color?
                    tools.push(new ColorTool(detail))
                else if detail.colorTools?
                    colorTools = _.filter tools, (a) ->
                        a.get('label') in detail.colorTools
                    opts = _.extend(
                        {colorTools: colorTools},
                        _.omit(detail, 'colorTools'))
                    tools.push(new SplitColorTool(opts))
            tools

        addToolInfos: (toolInfos, options) =>
            @add(@createTools(toolInfos), options)

        move: (tool, newIndex) =>
            oldIndex = @indexOf(tool)
            return if oldIndex == newIndex

            @remove(tool, {silent: true})
            @add(tool, {at: newIndex, silent: true})

            @trigger("change", @)
            @trigger("moved", tool, newIndex, oldIndex)
            tool.trigger("moved", @, newIndex, oldIndex)

        lastColorToolIndex: =>
            index = 0
            @some (tool) =>
                if tool.type == 'color'
                    index += 1
                    false
                else
                    true
            index

    class Palette extends Backbone.Model

        toolCollectionClass: ToolCollection

        initialize: (options) =>
            super
            @tools = new @toolCollectionClass()
            @tools.add(new RemoveColorTool())
            @tools.add(options.tools) if options.tools?
            @tools.addToolInfos(options.toolInfos) if options.toolInfos?
            @set('newWordColor', options.newWordColor or '#000000')

        getToolForLabel: (label) => @tools.find((i) => i.get('label') == label)
        getColorForLabel: (label) => @getToolForLabel(label)?.get('color')

    class EditorToolCollection extends ToolCollection

        initialize: (options) =>
            super
            @listenTo(@, 'change:selected', @onToolSelectedChange)

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

        onSelectedToolChange: (sender, selectedTool, options) =>
            selectedTool.set('selected', true)

        onToolSelectedChange: (sender, isSelected, options) =>
            @set('selectedTool', sender) if isSelected


    module.exports =
        EditorPalette: EditorPalette
