    'use strict'

    _ = require('underscore')
    $ = require('jquery')

    {template} = require('./../../templates')
    {BBox} = require('./../../../math/bboxes')
    {Point} = require('./../../../math/points')
    {EditorMode} = require('./../../constants')
    {BaseView} = require('./../base')
    {RenderableView} = require('./../renderable')
    {
        EditorColorModeButton
        EditorDivToggleButton
    } = require('./../buttons')
    {SplitColorTool} = require('./../../models/palette')


    PlaceholderView = class extends BaseView

        className: 'split-color-picker-placeholder'
        render: => @


    SplitColorPaletteEditButton = class extends EditorDivToggleButton

        className: "split-color-mode-button
            #{EditorDivToggleButton::className}"

        NOT_EDITING = 'not-editing'
        EDITING_EMPTY = 'editing-empty'
        EDITING = 'editing'

        IN_EDIT_STATES: [EDITING_EMPTY, EDITING]

        NOT_EDITING: NOT_EDITING
        EDITING: EDITING
        EDITING_EMPTY: EDITING_EMPTY

        states: [NOT_EDITING, EDITING_EMPTY, EDITING]
        defaultState: NOT_EDITING

        getIconCss: ->
            switch @currentState
                when NOT_EDITING then 'icon_brush'
                when EDITING then 'icon_minus-in-circle'
                when EDITING_EMPTY then 'icon_cancel'

        templateString: =>
            """
            <div class="centering-outer">
              <div class="centering-inner">
                <div class="icon #{ @getIconCss() }"></div>
              </div>
            </div>
            """

        initialize: (options) =>
            super
            @setOptions(options, ['$splitEditorContainer', 'pickerView'], true)
            @paletteModel = options.model
            @isEditingSetup = false
            @listenTo(
                @paletteModel, 'change:selectedTool',
                @onSelectedToolChange
            )

        onSelectedToolChange: (sender, newTool) ->
            # when selected tool changes editability can change
            @updateVisibility()
            @onPickerClosed(false)

        getNextState: =>
            if @currentState == @NOT_EDITING
                @EDITING_EMPTY
            else if @tempModel?.colorTools?.length > 0
                @EDITING
            else
                @EDITING_EMPTY

        onClick: =>
            if @currentState == @EDITING
                return @tempModel.popTool()
            if @currentState == @EDITING_EMPTY
                return @onPickerClosed(false)
            super

        onStateChange: (sender, value, options) =>
            super

            if value == @EDITING_EMPTY
                @startEditing() if not @isEditingSetup
            else if value == @NOT_EDITING
                @stopEditing() if @isEditingSetup

        remove: =>
            @stopEditing() if @isEditingSetup
            @stopListening(@)
            @stopListening(@paletteModel)
            @stopListening(@getEditor())
            delete @paletteModel
            super

        onPickerClosed: (confirmed) =>
            @updateOriginalModel() if confirmed
            @setState(@NOT_EDITING)

        updateOriginalModel: =>
            if @tempModel?.colorTools?.length > 0
                @paletteModel.get('selectedTool').reset(@tempModel.colorTools)

        startEditing: =>
            # this view is passe the tool to change based on user interaction
            # on successful edit it will replace tools of the active splitcolor
            @tempModel = new SplitColorTool()
            @listenTo(@tempModel, 'change', @onTempModelChange)
            @splitColorPicker = new SplitColorEditor
                editor: @getEditor()
                tempModel: @tempModel
                originalModel: @paletteModel.get('selectedTool')
            @listenTo(@splitColorPicker, 'click', @onPickerSubviewClicked)

            # $splitEditorContainer can be a function in case it couldn't be
            # defined on initialize time (eg. view was appended after)
            _.result(@, '$splitEditorContainer').append(
                @splitColorPicker.render().$el
            )
            @pickerView.toggleColorViews(false)
            @isEditingSetup = true

        stopEditing: =>
            @pickerView.toggleColorViews(true)
            @stopListening(@splitColorPicker)

            @splitColorPicker?.remove()
            delete @splitColorPicker

            @stopListening(@tempModel)
            delete @tempModel

            @isEditingSetup = false

        onTempModelChange: (sender, value) =>
            if @tempModel?.colorTools?.length > 0
                @setState(@EDITING)
            else
                @setState(@EDITING_EMPTY)

        onPickerSubviewClicked: (sender, model) =>
            if model == @tempModel
                @onPickerClosed(true)
            else
                @tempModel.pushTool(model)

        updateVisibility: ->
            @hidden = not @shouldShowEditButton()
            @toggleVisibility(not @hidden)

        render: ->
            @hidden = not @shouldShowEditButton()
            super

        canEdit: => @paletteModel?.get('selectedTool')?.type == 'splitcolor'

        shouldShowEditButton: =>
            @canEdit() and @getEditor().mode == EditorMode.COLOR

        toggleVisibility: (show, $el=@$el) ->
            show = @hidden if not show?
            $el.css('visibility', if show then 'visible' else 'hidden')


    PaletteColorViewBase = class extends RenderableView

        events:
            'click': 'onClick'

        className: "button color-palette__color-btn"
        template: template('./editor/colorpicker/color.ejs')

        initialize: ->
            @listenToColorChange()

        onClick: => @trigger('click', @, @model)

        listenToColorChange: -> @listenTo(@model, 'change:color', @render)


    ###Single color picker palette box base class.###
    PaletteColorView = class extends PaletteColorViewBase

        initialize: (options) =>
            super
            @setOption(options, 'editor', true)
            @listenTo(@model, 'change:selected', @render)
            if not @model.get('selected')?
                @model.set('selected', false, silent: true)
            @listenTo(@model, 'remove', @remove)
            @listenTo(@editor, 'change:mode', @onEditorModeChange)

        remove: =>
            @stopListening(@editor)
            delete @editor
            @stopListening(@model)
            delete @model
            super

        render: ->
            super
            @$el.toggleClass('active', @isSelected())
            @

        isSelected: => @model?.get('selected') or false

        onEditorModeChange: =>

        onClick: ->
            super

            @model.set('selected', true)
            @editor.setMode(EditorMode.COLOR)


    RemoveColorView = class extends PaletteColorView

        template: template('./editor/colorpicker/remove-color.ejs')


    ###Configures split color view rendering.###
    SplitColorPrototype =

        template: template('./editor/colorpicker/split-color.ejs')

        listenToColorChange: -> @listenTo(@model, 'change', @render)

        getRenderContext: (ctx={}) ->
            _.extend {
                modelColors: @model.getColors(),
            }, ctx

    ###Regular palette split color view.###
    PaletteSplitColorView = class extends PaletteColorView.extend(SplitColorPrototype)

        className: "#{PaletteColorView::className} color-palette-split-color"

    ###Split color palette color view.###
    SplitEditorColorView = class extends PaletteColorViewBase

        className: "#{PaletteColorViewBase::className} split-color"

    ###Split color editor split color view.###
    SplitEditorSplitColorView = class extends PaletteColorViewBase.extend(SplitColorPrototype)

        className: "#{PaletteColorView::className}
            split-editor-color-preview_done"

    SquarePickerBase = class extends RenderableView

        colorClass: null
        splitColorClass: null
        removeColorClass: RemoveColorView

        initialize: (options) =>
            super
            @setOptions(options, ['editor'], true)
            @setOptions(options, ['model'])
            @model ?= @editor.colorPalette
            @updateSubviews()
            @listenTo(@editor, 'selectchange', @onSelectChange)
            @listenTo(@editor, 'change:mode', @onEditorModeChange)

        onSelectChange: =>

        removePaletteViews: =>
            for own toolcid, view of @paletteViewsCache or {}
                @removeSubview(view)
            @paletteViewsCache.length = 0
            delete @paletteViewsCache

        remove: =>
            @removing = true

            @removePaletteViews()

            @stopListening(@editor)
            delete @editor

            @stopListening(@model)
            @stopListening(@model.tools)
            delete @model

            super

        reset: =>
            @updateSubviews()
            @render()

        createPaletteView: (options) =>
            options = _.extend(
                editor: @editor,
                options
            )
            switch options.model.type
                when 'color'
                    cls = @colorClass
                when 'splitcolor'
                    cls = @splitColorClass
                when 'removecolor'
                    cls = @removeColorClass
            view = new cls(options)

        getPaletteView: (options) =>
            @paletteViewsCache = {}
            view = @paletteViewsCache[options.model.cid]
            if not view?
                view = @createPaletteView(options)
                @paletteViewsCache[options.model.cid] = view
            view

        getPaletteViews: =>
            @model.tools.map (tool) => @getPaletteView(model: tool)

        getSubViews: =>
            '.color-palette-container': @getPaletteViews()

        updateSubviews: =>
            @subviews = @getSubViews()


    SquarePicker = class extends SquarePickerBase

        template: template('./editor/colorpicker/main.ejs')

        className: 'color-picker'
        colorClass: PaletteColorView
        splitColorClass: PaletteSplitColorView

        initialize: (options) =>
            super
            @listenTo @model.tools, 'add', @reset
            @listenTo @model.tools, 'remove', @reset
            @listenTo @editor, 'selectchange', @onSelectChange

        getColorModeButton: =>
            @colorModeButton ?= new EditorColorModeButton
                parentView: @
                customClassName: "icon icon_frame"
                model: @model
                editor: @editor
            @colorModeButton

        getEditButton: =>
            if not @editButton?
                @editButton = new SplitColorPaletteEditButton
                    $splitEditorContainer: => @$('.split-color-palette-container')
                    pickerView: @
                    editor: @editor
                    model: @model
                @listenTo(@editButton, 'change:state', @onEditorModeChange)
            @editButton

        getSubViews: () =>
            subviews = super
            subviews['.buttons-container'] = [@getEditButton()]
            subviews['.color-mode-button-container'] = [@getColorModeButton()]
            subviews

        remove: =>
            @removeSubview('editButton')
            super

        toggleColorViews: (show) =>
            @$('.color-palette-container').toggle(show)

    SplitColorEditor = class extends SquarePickerBase

        className: 'buttons-group split-color-editor'
        colorClass: SplitEditorColorView
        splitColorClass: SplitEditorSplitColorView

        initialize: (options) =>
            @originalModel = options.originalModel
            @tempModel = options.tempModel
            super

        remove: (options) =>
            @removeSubview('placeholderView')
            delete @originalModel
            delete @tempModel
            super

        createPaletteView: (options) =>
            if options.model == @originalModel
                options.model = @tempModel
            view = super(options)
            @listenTo(view, 'click', @onChildSubviewClicked)
            view

        ###Empty view to cover the color mode switch button.###
        getPlaceholderView: =>
            @placeholderView ?= new PlaceholderView({})

        ###Replace the original color mode button with a placeholder.###
        getSubViews: =>
            '': [@getPlaceholderView()].concat(@getPaletteViews())

        ###Forward child clicks.###
        onChildSubviewClicked: (sender, model) => @trigger('click', @, model)


    module.exports =
        SquarePicker: SquarePicker
