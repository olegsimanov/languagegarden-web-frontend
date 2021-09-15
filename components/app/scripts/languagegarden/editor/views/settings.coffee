    'use strict'

    require('raphael')
    _ = require('underscore')
    $ = require('jquery')
    require('../settings-dependencies')
    {
        createColorPicker
        ColorSelectView
    } = require('./../../common/views/colorpicker')
    {BaseView} = require('./../../common/views/base')
    {RenderableView} = require('./../../common/views/renderable')
    {SimpleNavMenu, Panel} = require('./../../common/views/menu')
    {TextSize} = require('./../../common/constants')
    {enumerate} = require('./../../common/utils')
    {template} = require('./../../common/templates')
    {PlantElement} = require('./../../common/models/elements')
    {SettingsElementView} = require('./../../common/views/elements')
    {ColorTool} = require('./../../common/models/palette')
    {Point} = require('./../../math/points')
    editorColors = require('./../colors')
    settings = require('./../../settings')


    class SettingsPanel extends Panel

        initialize: (options) ->
            @setPropertyFromOptions(options, 'parent', required: true)
            @setPropertyFromOptions(options, 'canvasView',
                                    default: @parent.canvasView
                                    required: true)
            @setPropertyFromOptions(options, 'model',
                                    default: @parent.model
                                    required: true)
            @setPropertyFromOptions(options, 'dataModel',
                                    default: @parent.dataModel
                                    required: true)
            @setPropertyFromOptions(options, 'timeline',
                                    default: @parent.timeline
                                    required: true)

            # for deprecated usage
            # TODO: remove it
            @editor = @canvasView

            options.model = @model
            super

        remove: ->
            delete @parent
            delete @model
            delete @editor
            delete @canvasView
            super


    class ColorPaletteRow extends RenderableView

        template: template('./editor/settings/panels/color_palette_row.ejs')
        editable: true

        tagName: 'tr'
        className: "palette-item"

        events:
            'click .color-palette-remove': 'onRemoveClick'
            'change .item-color select': 'onColorChange'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'parent', required: true)
            # ColorTool instance
            @setPropertyFromOptions(options, 'model')
            @listenTo(@model, 'remove', @remove) if @model

        remove: =>
            @trigger('removing', @)
            @stopListening(@model)
            delete @parent
            delete @model
            super
            @trigger('removed', @)

        render: =>
            super
            @delegateEvents()
            @$el.attr('id', @model.id) if @model?

            @$('.item-color').each (i, td) =>
                createColorPicker
                    $el: @$(td)
                    colors: @parent?.getPickerColors()
                    initial: @model?.get('color')
                    pickerOptions:
                        picker: true

            @$colorSelect = @$('.item-color select')
            @setupEditable()
            @

        setupEditable: =>
            @$labelTd = @$('td.item-label')
            @$label = @$labelTd.find('span')
            @$label.editable
                mode: 'inline'
                emptyclass: 'muted'
                emptytext: 'No label'
                unsavedclass: ''

            # change css classes to prevent hopping due to changing size
            @$label.on 'hidden', (e) =>
                @$labelTd.removeClass('item-label-in-edit')
            @$label.on 'shown', (e) =>
                @$labelTd.addClass('item-label-in-edit')

            @$label.on 'save', @onLabelChange
            @$label

        onLabelChange: (e, params) =>
            if @model.get('label') != params.newValue
                @model.set('label', params.newValue)

        onColorChange: (event) =>
            newValue = @$colorSelect.val()?.trim()
            if @model.get('color') != newValue
                @model.set('color', newValue)

        onRemoveClick: (event) => @model.collection.remove(@model)


    class ColorPaletteNewItemRow extends ColorPaletteRow

        editable: false
        className: "palette-item item-label-in-edit"
        events:
            'click .color-palette-add': 'onAddClick'
            'keyup .new-item-label input': 'onLabelKeyup'

        render: =>
            super
            @$labelInput = @$('.new-item-label input')
            @$colorSelect = @$('.new-item-color select')
            @

        onLabelKeyup: (event) => @onAddClick() if event.keyCode == 13

        onAddClick: (event) =>
            newTool = new ColorTool
                color: @$colorSelect.val()
                label: @$labelInput.val()
            @parent.editor.colorPalette.tools.addColorTool(newTool)
            @$labelInput.val('')

        onRowChange: (event) => # no-op


    class ColorPalettePanel extends SettingsPanel

        title: 'Color palette'
        menuName: 'Color palette'
        template: template('./editor/settings/panels/color_palette.ejs')
        rowsSelector: 'table#color_palette_sortable'

        initialize: (options) =>
            super
            @colorPalette = @editor.colorPalette
            @getPickerColors()
            @colorViews = []
            for model in @colorPalette.tools.getEditable()
                colorView = new ColorPaletteRow
                    parent: @
                    model: model
                @colorViews.push colorView
                @listenTo(colorView, 'removed', @onSubViewRemoved)

            @newItemView = new ColorPaletteNewItemRow
                parent: @

            @listenTo(@colorPalette.tools, 'add', @onToolAdded)

        onSubViewRemoved: (subview) =>
            @stopListening(subview)
            @colorViews = _.without @colorViews, subview

        remove: =>
            @stopListening(@colorPalette)
            @newItemView?.remove()
            for view in @colorViews or []
                @stopListening(view)
                view.remove()
            @colorViews = []
            delete @newItemView
            delete @colorPalette
            super

        render: =>
            super
            @delegateEvents()
            @renderSubview @rowsSelector, @colorViews.concat(@newItemView)

            @$sortable = @$(@rowsSelector)
            @$sortable.sortable
                items: 'tr:not(:last-child)'
                handle: '.item-handle'
                containment: "parent"
                forcePlaceholderSize: true
                helper: @createHelper
                update: @onRowPositionUpdateEnd
                start: @onRowPositionUpdateStart
            @

        ### Helper is displayed under the cursor while dragging. ###
        createHelper: (event, ui) =>
            display = ui.clone()
            display.children('td.item-controls').remove()
            display

        # Event handlers
        onRowPositionUpdateStart: (event, ui) =>
            # store the tool to move
            @_movingIndex = ui.item.index()

        onRowPositionUpdateEnd: (event, ui) =>
            tool = @colorPalette.tools.at(@_movingIndex)
            newIndex = ui.item.index()
            oldIndex = @_movingIndex

            # TODO: make this happen on move event
            # simply move existing color views around
            toolRow = @colorViews.splice(oldIndex, 1)[0]
            @colorViews.splice(newIndex, 0, toolRow)
            @colorPalette.tools.move(tool, newIndex)

        onToolAdded: (model) =>
            colorView = new ColorPaletteRow
                parent: @
                model: model
            index = model.collection.indexOf(model)
            @colorViews.splice(index, 0, colorView)
            @newItemView.$el.before(colorView.render().$el)
            @listenTo(colorView, 'removed', @onSubViewRemoved)


        # Available colors
        getPickerColors: =>
            if not @colors?
                @colors = []
                for tool in @colorPalette.tools.getEditable()
                    if tool.get('color')?
                        @colors.push
                            color: tool.get('color')
                            label: tool.get('color')
                for color in editorColors.colorPalette
                    @colors.push
                        color: color
                        label: color
            @colors


    class FontPanelWordPreview extends BaseView

        text: 'example'

        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'editor', required: true)
            @setPropertyFromOptions(options, 'text', default: @text)
            @setPropertyFromOptions(options, 'slider', required: true)

            # default spacing is just too big
            @spacePercent = -0.18
            @wordY = 100
            @wordStartX = 0

            @model = new PlantElement
                text: @text
                fontSize: @editor.settings.get('fontSize')

            @$el.measurementCache ?= @measureDomNode(@$el)
            @updateWordToContainerSize(@$el.measurementCache...)

            @listenTo(@slider, 'slider:change', @onFSChange)
            @listenTo(@slider, 'slider:stop', @onSliderStop)

        onSliderStop: (sender, newVal, oldVal) =>
            @editor.settings.save('fontSize', newVal)

        onFSChange: (sender, newVal, oldVal) =>
            @model.applyFontSize(newVal)
            @wordView.updateTextPath()

        render: (options) =>
            @paper = Raphael(@el, '100%', '100%')

            @wordView = new SettingsElementView
                letterMetrics: @editor.letterMetrics
                paper: @paper
                model: @model
                letterFill: editorColors.previewPanelWordColor

            @wordView.render()

        measureDomNode: (node) =>
            cloned = node.clone()
            $measureEl = $('<div>').css('visibility', 'hidden')
                .addClass('measuring-div').html(cloned).appendTo(document.body)
            m = [cloned.width(), cloned.height()]
            $measureEl.remove()
            m

        getPathLenght: =>
            lengthAcc = 0
            fontSize = @model.get('fontSize')
            spacePerElement = fontSize * @spacePercent
            for l in @model.get('text').split('')
                lengthAcc += @editor.letterMetrics.getLength(l, fontSize)
                lengthAcc += spacePerElement
            lengthAcc

        getWordControlPoints: =>
            [x1, x2] = [@wordStartX, @wordStartX + @getPathLenght()]
            startPoint = new Point(x1, @wordY)
            startPoint = @model.convertPointToPathCoordinates(startPoint)
            endPoint = new Point(x2, @wordY)
            controlPoint = new Point(
                (startPoint.x + endPoint.x) / 2, startPoint.y)
            [startPoint, controlPoint, endPoint]

        updateWordToContainerSize: (width, height) =>
            [startPoint, controlPoints..., endPoint] = @getWordControlPoints()
            @model.set('startPoint', startPoint)
            @model.set('controlPoints', controlPoints)
            @model.set('endPoint', endPoint)

        onScaleChange: (sender, newVal, oldVal) =>
            @model.applyFontSize(newVal)
            @wordView.updateTextPath()


    class FontPanelSlider extends BaseView

        initialize: (options) =>
            @editor = options.editor

        render: =>
            @$el.slider
                min: settings.minFontSize
                max: settings.maxFontSize
                value: @editor.settings.get('fontSize')
                orientation: 'horizontal'
                slide: @onSlide
                step: 1
                stop: @onStop

        onEvent: (event, ui, eventName) =>
            newFS = ui.value
            @trigger(eventName, @, newFS, oldFS) if newFS != oldFS
            oldFS = newFS

        onStop: (event, ui) => @onEvent(event, ui, 'slider:stop')
        onSlide: (event, ui) => @onEvent(event, ui, 'slider:change')


    class FontPanelBgColorSelectView extends ColorSelectView

        picker: false

        initialize: (options) =>
            @editor = options.editor
            @model = options.model
            options.colors = @editor.bgColorChoices
            options.initial = @model.get 'bgColor'
            super
            @listenTo(@model, 'change:bgColor', @onBgColorChange)
            @listenTo(@editor, 'change:bgColorChoices', @render)

        onBgColorChange: (editor, value) =>
            if @rendered and @$picker.val() != value
                @$picker?.val(value)

        onValueSelected: =>
            @model.set 'bgColor', @$picker.val()
            @editor.history.makeSnapshot()

        render: =>
            @initial = @model.get 'bgColor'
            @colors = @editor.bgColorChoices
            super
            @$picker.change @onValueSelected
            @rendered = true

        remove: =>
            @stopListening @model
            @stopListening @editor
            delete @editor
            delete @model
            super


    class FontPanel extends SettingsPanel

        title: 'Font'
        menuName: 'Font'
        template: template('./editor/settings/panels/font.ejs')

        initialize: (options) =>
            super
            @sizeSlider = new FontPanelSlider
                editor: @editor

            @wordPreview = new FontPanelWordPreview
                editor: @editor
                slider: @sizeSlider

            @bgColorSelect = new FontPanelBgColorSelectView
                editor: @editor
                model: @model

            @subViews =
                '#font_panel_slider': @sizeSlider
                '#font_panel_word_preview': @wordPreview
                '#font_panel_bgpicker': @bgColorSelect


        render: (options) =>
            super
            @renderSubview(@subViews)
            @


    class PlantDetailsPanel extends SettingsPanel

        title: 'Plant details'
        menuName: 'Plant details'
        template: template('./editor/settings/panels/plant_details.ejs')

        setupEditables: =>
            @setupEditable 'a#inputTitle', 'text', 'title'
            @setupEditable 'a#inputDescription', 'textarea', 'description'
            @setupEditable 'a#inputTextDirection', 'text', 'textDirection'

        setupEditable: (selector, type, modelAttribute, options) =>
            $item = @$(selector)
            $item.data('modelAttribute', modelAttribute)
            $item.editable
                mode: 'inline'
                emptyclass: 'muted'
                emptytext: 'Click to change'
                unsavedclass: ''
                type: type
                value: @dataModel.get(modelAttribute)

            $item.on 'save', @onEditableSave
            $item

        onEditableSave: (e, params) =>
            @dataModel.set($(e.target).data('modelAttribute'), params.newValue)
            @timeline.saveModel()

        render: (options) =>
            super
            @setupEditables()
            @


    class NotePanel extends SettingsPanel

        title: 'Notes'
        menuName: 'Notes'
        template: template('./editor/settings/panels/notes.ejs')

        getSelectOptions: =>
            for val in TextSize.NOTE_SIZES
                value: val
                text: TextSize.DISPLAY_NAMES[val]

        setupEditables: =>
            @setupModelEditable(
                @editor.settings, 'a#inputTextSize', 'select', 'textSize',
                source: @getSelectOptions()
            )

        setupModelEditable: (model, selector, type, modelAttribute, options) =>
            $item = @$(selector)

            opts =
                mode: 'inline'
                unsavedclass: ''
                type: type
                value: model.get(modelAttribute)

            $item.editable(_.extend(opts, options))
            $item.data('modelAttribute', modelAttribute)
            $item.on 'save', (e, params) =>
                @onModelEditableSave(e, params, model)
            $item

        onModelEditableSave: (e, params, model) =>
            model.save($(e.target).data('modelAttribute'), params.newValue)

        render: (options) =>
            super
            @setupEditables()
            @


    class SettingsMenu extends SimpleNavMenu

        title: 'Settings'
        template: template('./editor/settings/main.ejs')
        extra_css: 'settings-menu-modal'

        panels: [
            FontPanel,
            # We Don't need it now, but we might in the feature
            # NotePanel
            ColorPalettePanel,
            PlantDetailsPanel,
        ]

        initialize: (options) ->
            @setPropertyFromOptions(options, 'canvasView', required: true)
            @setPropertyFromOptions(options, 'model', required: true)
            @setPropertyFromOptions(options, 'dataModel', required: true)
            @setPropertyFromOptions(options, 'timeline', required: true)
            super


    module.exports =
        SettingsMenu: SettingsMenu
