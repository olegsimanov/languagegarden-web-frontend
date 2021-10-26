    'use strict'

    _                           = require('underscore')
    Hammer                      = require('hammerjs')

    {disableSelection}          = require('./utils/dom')

    {BaseView}                  = require('./base')
    {
        TemplateView
        createTemplateWrapper
    }                           = require('./template')

    {Point}                     = require('./../math/points')
    {BBox}                      = require('./../math/bboxes')
    {SplitColorTool}            = require('./../models/palette')
    utils                       = require('./../utils')


    {
        SaveAndGoToNavigatorAction
        DiscardAndGoToNavigatorAction
    }                           = require('./../actions/navigation')
    {SplitWordElement}          = require('./../actions/split')
    {DeleteAction}              = require('./../actions/delete')
    {
        SwitchToRotate
        SwitchToStretch
        SwitchToGroupScale
        SwitchToScale
        SwitchToMove
    }                           = require('./../actions/modeswitch')
    {StartUpdating}             = require('./../actions/edit')
    StartUpdatingText           = require('./../actions/edittext').StartUpdating

    {
        CanvasMode
        ColorMode
        ToolbarEnum
    }                           = require('./../constants')

    settings                    = require('./../../settings')



    class ButtonView extends BaseView

        tagName:            'div'
        className:          'button'
        toggledClassName:   'active'

        fadeEffects:        false
        disabled:           false
        hidden:             false

        help:               null

        initialize: (options) ->
            super

            @initializeProperties(options)

            if @action? or @actionClass?
                @initializeAction(options)

            @$el.attr('title', @help) if @help?

            @onClick ?= (event) =>
                event.preventDefault()
                console.error('unsupported button click!')

            Hammer(@el).on('tap', (event) => @onClick(event))

            @delegateEvents()
            disableSelection(@el)

        initializeProperties: (options) ->

            @setOption(options, 'parentEl', @parentView?.el)
            @setOption(options, 'position', null, false, null, Point.fromValue)
            @setOption(options, 'width')
            @setOption(options, 'height')
            @setOption(options, 'customClassName')
            @setOption(options, 'templateString')
            @setOption(options, 'hidden', null, false, 'show', (x) -> not x)
            @setOption(options, 'hidden')
            @setOption(options, 'disabled')
            @setOption(options, 'fadeEffects')
            @setOption(options, 'onClick')
            @setOption(options, 'help')
            @setOption(options, 'action')
            @setOption(options, 'actionClass')

        initializeAction: (options)     ->

            @action             ?= new @actionClass(@getActionOptions(options))
            @customClassName    ?= "button #{ @action.id }-button"
            @help               ?= @action.getHelpText()
            @onClick            ?= (event) =>
                                    if not @action.isAvailable()
                                        return true
                                    event.preventDefault()
                                    @action.fullPerform()

            @listenTo(@action, 'change:available', @render)
            @listenTo(@action, 'change:toggled', @render)

        getActionOptions: ->
            controller: @controller

        remove: =>
            delete @onClick
            super

        isToggled: -> @action?.isToggled() or false

        isEnabled: ->
            enabled = @action?.isAvailable()
            enabled ?= not @disabled
            enabled

        isDisabled: -> not @isEnabled()

        render: =>
            @delegateEvents()
            if @customClassName?
                @$el.addClass(@customClassName)

            @$el.html(_.result(@, 'templateString')) if @templateString?
            @toggleVisibility(not @hidden)
            @$el.toggleClass('disabled', @isDisabled())
            @$el.css(@getElCss())
            @$el.toggleClass(@toggledClassName, @isToggled())
            @appendToContainerIfNeeded()
            this

        getElCss: =>
            elCss = {}
            elCss.left = @position.x if @position?
            elCss.top = @position.y if @position?
            elCss.width = @width if @width?
            elCss.height = @height if @height?
            elCss

        toggleVisibility: (show) =>
            if show?
                @hidden = not show
            else
                @hidden = not @hidden

            if @hidden
                if @fadeEffects
                    @$el.fadeOut('fast')
                else
                    @$el.addClass('hide')
            else
                if @fadeEffects
                    @$el.fadeIn('fast')
                else
                    @$el.removeClass('hide')

        hide: => @toggleVisibility(false)

        show: => @toggleVisibility(true)

    class TooltipButtonView extends ButtonView

        fadeEffects:                false
        shouldAppendToContainer:    false

        onClick: -> @action.fullPerform()


    class NavButtonView extends ButtonView

        navTarget: null
        eventName: null

        initialize: (options) ->
            @initializeNavButton(options)
            super

        initializeNavButton: (options) ->
            @setOption(options, 'navTarget', undefined, true)
            @setOption(options, 'eventName', @getNavEventName(), true)
            @customClassName = @getNavButtonClass()

        getNavButtonClass: (navTarget=@navTarget)   -> "toolbar-button-#{ utils.slugify(@navTarget) }"
        getNavEventName: (navTarget=@navTarget)     -> "toolbarnav:#{ utils.slugify(navTarget) }"

        onClick: (e)    => @navButtonOnClick()
        isEnabled:      -> true

        navButtonOnClick: ->
            if not @isEnabled()
                return true
            @triggerToolbarNavEvent()

        triggerToolbarNavEvent:                          -> @trigger(@eventName, @, @navTarget)


    class BackButtonView extends NavButtonView

        navTarget:              'back'
        getNavButtonClass:      -> "#{super} icon icon_back"


    class PaletteNavButtonView extends NavButtonView

        getNavButtonClass: -> "#{super} icon icon_palette"

        initialize: (options) ->
            super
            @setOption(options, 'controller', undefined, true)
            @listenTo(@controller.canvasView, 'selectchange', @onSelectChange)
            @hidden = @shouldHide()

        onSelectChange: ->
            @hidden = @shouldHide()
            @render()

        shouldHide: -> @controller.canvasView.getSelectedElements().length == 0

        remove: ->
            @stopListening(@controller.canvasView)
            delete @controller
            super




    class EditorToolbarView extends TemplateView

        template:                   createTemplateWrapper('./common/toolbars/navigator.ejs')

        toolbarViewAnchors:
            '.station-navigator':           'plantNavMenu'
            '.toolbar__section_mid':        'contentMenu'
            '.toolbar__section_right':      'controlButtonsMenu'

        toolbarName:                'toolbar-name-missing'
        fallbackActionViewClass:    ButtonView

        getToolbarViewAnchors:      -> @toolbarViewAnchors

        initialize: (options) ->
            @active = true
            super
            @initSubviews()

        initSubviews: ->
            @subviews ?= {}
            for key, value of @getToolbarViewAnchors()
                @subviews[key] = _.compact(_.map(@[value], @initSubview))

        initSubview: (viewData) =>
            if viewData.show? and not viewData.show(@)
                return
            @createSubview(viewData)

        getSubviewClass: (viewData) ->
            viewClass = viewData.viewClass
            if not viewClass? and viewData.actionClass?
                viewClass = class AutogenMenuActionButton extends @fallbackActionViewClass
                    actionClass: viewData.actionClass
            if not viewClass?
                console.log(JSON.stringify(viewData))
                throw "Missing toolbar element configuration!"
            viewClass

        createSubview: (viewData) =>
            viewClass = @getSubviewClass(viewData)
            @postProcessSubView(
                new viewClass(@getSubviewOptions(viewData)),
                viewData
            )

        postProcessSubView: (view, viewData) =>
            switch viewData.viewType
                when 'navbutton'
                    @addEventForwarding(view, view.eventName)
                    @forwardedToolbarNavEvents ?= []
                    @forwardedToolbarNavEvents = _.uniq(
                        @forwardedToolbarNavEvents.concat([view.eventName])
                    )
            view

        addEventForwarding: (view, eventName, keepSource=false) =>
            @listenTo view, eventName, (source, args...) ->
                @trigger(eventName, (if keepSource then source else @), args...)

        getSubviewOptions: (viewData) =>

            switch viewData.viewType
                when 'navbutton'
                    args =
                        controller:                 @controller
                        editor:                     @controller.canvasView
                when 'button'
                    args =
                        controller:                 @controller
                        editor:                     @controller.canvasView
                when 'buttongroup'
                    args =
                        controller:                 @controller
                        canvasView:                 @controller.canvasView
                        model:                      @controller.model
                        shouldAppendToContainer:    false
                when 'palette'
                    args =
                        editor:                     @controller.canvasView
                        model:                      @controller.canvasView.editorPalette
                        shouldAppendToContainer:    false
                else
                    console.error("Uknown view type: #{viewData.viewType}")

            _.extend(args, viewData.context) if viewData.context?
            _.extend(args, viewData.getContext(@)) if viewData.getContext?
            args

        remove: ->
            @removeAllSubviews()
            delete @controller
            delete @forwardedToolbarNavEvents
            super

        render: ->
            super
            @$('.toolbar').addClass(@getToolbarCssClass())
            @updateVisibility()
            @

        getToolbarCssClass: -> "toolbar-#{ utils.slugify(@toolbarName) }"

        setActive: (value) ->
            if @active == value
                return

            @active = value
            @updateVisibility()
            @onActiveChanged()

        updateVisibility: -> @$('.toolbar').toggleClass('toolbar_active', @active)

        onActiveChanged: ->

    class EditorSubToolbarView extends EditorToolbarView

        template: createTemplateWrapper('./common/toolbars/container.ejs')

        backNav: [
            viewType: 'navbutton'
            viewClass: BackButtonView,
        ]

        toolbarViewAnchors:
            '.toolbar__section_left':   'backNav'
            '.toolbar__section_mid':    'contentMenu'
            '.toolbar__section_right':  'rightSide'




    class SelectionButtonGroupView extends BaseView

        buttonViewClass:            TooltipButtonView
        className:                  "buttons-group buttons-group_selection"
        shouldAppendToContainer:    true

        actionSpec:                 [
                                        id:             'switch-to-rotate'
                                        actionClass:    SwitchToRotate
                                        className:      'tooltip-switch-to-rotate icon icon_refresh'
                                        help:           'Switch to rotate'
                                    ,
                                        id:             'switch-to-scale'
                                        actionClass:    SwitchToScale
                                        className:      'tooltip-switch-to-scale icon icon_scale'
                                        help:           'Switch to scale'
                                    ,
                                        id:             'switch-to-group-scale'
                                        actionClass:    SwitchToGroupScale
                                        className:      'tooltip-switch-to-scale icon icon_scale'
                                        help:           'Switch to scale'
                                    ,
                                        id:             'switch-to-move'
                                        actionClass:    SwitchToMove
                                        className:      'tooltip-switch-to-move icon icon_move'
                                        help:           'Switch to move'
                                    ,
                                        id:             'switch-to-stretch'
                                        actionClass:    SwitchToStretch
                                        className:      'tooltip-switch-to-stretch icon icon_stretch'
                                        help:           'Switch to stretch'
                                    ,
                                        id:             'wordsplit'
                                        actionClass:    SplitWordElement
                                        className:      'tooltip-word-split icon icon_scissors'
                                        help:           'Split word at cursor'
                                    ,
                                        id:             'edit'
                                        actionClass:    StartUpdating
                                        className:      'tooltip-edit icon icon_pencil'
                                        help:           'Edit'
                                    ,
                                        id:             'edittext'
                                        actionClass:    StartUpdatingText
                                        className:      'tooltip-edit'
                                        help:           'Edit'
                                    ,
                                        id:             'delete'
                                        actionClass:    DeleteAction
                                        className:      'tooltip-bin icon icon_trash'
                                        help:           'Delete selected'
                                    ]


        initialize: (options) ->
            super
            @setPropertyFromOptions(options, 'canvasView',{ default: @controller?.canvasView }, required: true)
            @setPropertyFromOptions(options, 'model', { default: @controller?.model }, required: true)
            @buttonInfos = (@createButtonInfo(spec) for spec in @actionSpec)
            for buttonInfo in @buttonInfos
                @listenTo(buttonInfo.action, 'change:available', @invalidate)
            @rendered = false
            @prevState = null

        remove: ->
            @stopListening(@canvasView)
            for buttonInfo in @buttonInfos
                buttonInfo.buttonView.remove()
            @canvasView = null
            @model = null
            super

        createButtonInfo: (spec) ->
            action = new spec.actionClass
                controller: @controller
                canvasView: @canvasView

            btnCls = spec.viewClass or @buttonViewClass
            customClassName = "tooltip-button #{spec.className}"

            buttonView = new btnCls
                controller: @controller
                canvasView: @canvasView
                parentView: this
                action: action
                customClassName: customClassName
                help: spec.help

            buttonInfo =
                action: action
                spec: spec
                buttonView: buttonView

            buttonInfo

        renderCore: ->
            state = ({
                available: buttonInfo.action.isAvailable()
            } for buttonInfo in @buttonInfos)

            if _.isEqual(@prevState, state)
                # this condition avoids unnecessary re-inserting button DOM
                # elements into this.el (and killing click events, which
                # is a side effect) when state did not change.
                return

            @$el.empty()
            for i in [0...@buttonInfos.length]
                buttonInfo = @buttonInfos[i]
                st = state[i]
                if not st.available
                    continue
                buttonInfo.buttonView.render()
                @$el.append(buttonInfo.buttonView.el)


            @prevState = state
            @rendered = true

        invalidate: ->
            if @rendered
                @render()
            this


    class TooltipToolbarView extends EditorToolbarView

        toolbarName: ToolbarEnum.BUILDER

        plantNavMenu: [
            actionClass:    DiscardAndGoToNavigatorAction
            viewType:       'button'
            context:        {customClassName: 'icon icon_back'}
        ]

        contentMenu: [
            viewClass:      SelectionButtonGroupView,
            viewType:       'buttongroup'
        ]

        controlButtonsMenu: [

            viewClass:      PaletteNavButtonView
            viewType:       'navbutton'
            context:        {navTarget: ToolbarEnum.COLOR}
        ,
            actionClass:    SaveAndGoToNavigatorAction
            viewType:       'button'
            context:        {customClassName: 'icon icon_check'}

        ]

    class PlaceholderView extends BaseView

        className:  'split-color-picker-placeholder'
        render:     => @


    StateButtonViewPrototype =

        getStateCssClass: (state) -> "button-state-#{utils.slugify(state)}"
        updateStateCss: (currentState=@currentState) ->
            for st in @states
                @toggleClass(@getStateCssClass(st), st == currentState)

    StatefulClassPrototype =

        getCurrentStateIndex:   -> _.indexOf(@states, @currentState)
        getNextStateIndex:      -> (@getCurrentStateIndex() + 1) % @states.length
        getNextState:           -> @states[@getNextStateIndex()]

        setState: (state, options={}) ->
            state = @defaultState if not _.contains(@states, state)

            if state != @currentState
                @currentState = state
                if options.silent
                    return
                @trigger('change', @)
                @trigger('change:state', @, state)

        setupStates: (stateOptions) ->
            setDefault = (name, val) => @[name] = val if not @[name]?
            setIfPresent = (name) =>
                @[name] = stateOptions[name] if stateOptions[name]?

            setIfPresent('states')
            setIfPresent('defaultState')
            setIfPresent('currentState')
            setIfPresent('initialState')

            # set defaults if missing
            setDefault('defaultState', @states[0])
            setDefault('initialState', @defaultState)
            setDefault('currentState', @initialState)

    StateButtonBaseView = ButtonView
        .extend(StatefulClassPrototype)
        .extend(StateButtonViewPrototype)

    class StateButtonView extends StateButtonBaseView

        className: "#{ButtonView::className} state-button"

        initialize: (options) ->
            super
            @setupStates(options)
            @listenTo(@, 'change:state', @onStateChange)

        toggleClass: (cls, isEnabled) -> @$el.toggleClass(cls, isEnabled)

        remove: =>
            @stopListening(@)
            super

        render: =>
            super
            @updateStateCss()
            @

        onStateChange: (sender, value, options) =>
            @render()


    class ToggleButtonView extends StateButtonView

        onClick: (e) -> @setState(@getNextState())


    class EditorToggleButtonView extends ToggleButtonView

        initialize: (options) ->
            options.parentView = options.editor if options?.editor?
            super

        getEditor: -> @parentView


    class SplitColorPaletteEditButtonView extends EditorToggleButtonView

        className: "split-color-mode-button #{EditorToggleButtonView::className}"

        NOT_EDITING     = 'not-editing'
        EDITING_EMPTY   = 'editing-empty'
        EDITING         = 'editing'

        IN_EDIT_STATES: [EDITING_EMPTY, EDITING]

        NOT_EDITING:        NOT_EDITING
        EDITING:            EDITING
        EDITING_EMPTY:      EDITING_EMPTY

        states:             [NOT_EDITING, EDITING_EMPTY, EDITING]
        defaultState:       NOT_EDITING

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
            @setOption(options, '$splitEditorContainer', undefined, true)
            @setOption(options, 'pickerView', undefined, true)
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
            @splitColorPicker = new SplitColorEditorView
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
            @canEdit() and @getEditor().mode == CanvasMode.COLOR

        toggleVisibility: (show, $el=@$el) ->
            show = @hidden if not show?
            $el.css('visibility', if show then 'visible' else 'hidden')


    class PaletteColorViewBase extends TemplateView

        events:
            'click': 'onClick'

        className:  "button color-palette__color-btn"
        template:   createTemplateWrapper('./editor/colorpicker/color.ejs')

        initialize:             -> @listenToColorChange()
        onClick:                => @trigger('click', @, @model)
        listenToColorChange:    -> @listenTo(@model, 'change:color', @render)


    ###Single color picker palette box base class.###
    class PaletteColorView extends PaletteColorViewBase

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
            @editor.setMode(CanvasMode.COLOR)


    class RemoveColorView extends PaletteColorView

        template:               createTemplateWrapper('./editor/colorpicker/remove-color.ejs')


    ###Configures split color view rendering.###
    SplitColorPrototype =

        template:               createTemplateWrapper('./editor/colorpicker/split-color.ejs')

        listenToColorChange:                    -> @listenTo(@model, 'change', @render)
        getRenderContext:       (ctx={})    -> _.extend({modelColors: @model.getColors()}, ctx)

    class PaletteSplitColorView extends PaletteColorView.extend(SplitColorPrototype)

        className: "#{PaletteColorView::className} color-palette-split-color"


    class SplitEditorColorView extends PaletteColorViewBase

        className: "#{PaletteColorViewBase::className} split-color"



    class SplitEditorSplitColorView extends PaletteColorViewBase.extend(SplitColorPrototype)

        className: "#{PaletteColorView::className} split-editor-color-preview_done"

    class SquarePickerBaseView extends TemplateView

        colorClass:         null
        splitColorClass:    null
        removeColorClass:   RemoveColorView

        initialize: (options) =>
            super
            @setOption(options, 'editor', undefined, true)
            @setOption(options, 'model')
            @model ?= @editor.colorPalette
            @updateSubviews()
            @listenTo(@editor, 'selectchange',  @onSelectChange)
            @listenTo(@editor, 'change:mode',   @onEditorModeChange)

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


    class SplitColorEditorView extends SquarePickerBaseView

        className:          'buttons-group split-color-editor'
        colorClass:         SplitEditorColorView
        splitColorClass:    SplitEditorSplitColorView

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
        getPlaceholderView: => @placeholderView ?= new PlaceholderView({})

        ###Replace the original color mode button with a placeholder.###
        getSubViews: =>
            '': [@getPlaceholderView()].concat(@getPaletteViews())

        ###Forward child clicks.###
        onChildSubviewClicked: (sender, model) => @trigger('click', @, model)


    class SquarePickerView extends SquarePickerBaseView

        template:           createTemplateWrapper('./editor/colorpicker/main.ejs')

        className:          'color-picker'
        colorClass:         PaletteColorView
        splitColorClass:    PaletteSplitColorView

        initialize: (options) =>
            super
            @listenTo @model.tools,         'add',          @reset
            @listenTo @model.tools,         'remove',       @reset
            @listenTo @editor,              'selectchange', @onSelectChange

        getColorModeButton: =>
            @colorModeButton ?= new EditorColorModeButtonView
                parentView: @
                customClassName: "icon icon_frame"
                model: @model
                editor: @editor
            @colorModeButton

        getEditButton: =>
            if not @editButton?
                @editButton = new SplitColorPaletteEditButtonView
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


    class StatefulToolbarBaseView extends TemplateView.extend(StatefulClassPrototype)

        defaultState:   null
        toolbarClasses: null

        # Map of label to children class {stateName: toolbarClass}
        toolbars:       undefined
        getToolbars:    => @toolbars

        initialize: (options) =>

            @toolbars = _.object(_.map(
                @toolbarClasses, (tbc) -> [tbc::toolbarName, tbc]
            ))
            @states = _.keys(@toolbars)

            super
            @setOption(options, 'toolbars', undefined, true)
            @setupStates(options)
            @toolbarViews = @createToolbarViews(options)
            @listenTo(@, 'change:state', @onStateChange)
            @setActiveView(@currentState)

            @subviews = {'': _.values(@toolbarViews)}

        createToolbarViews: (options) =>
            toolbarViews = {}
            for own stateName, toolbarClass of @getToolbars()
                toolbarViews[stateName] = tv = new toolbarClass(
                    @getToolbarOptions(options)
                )
                for eventName in tv.forwardedToolbarNavEvents or []
                    @listenTo(tv, eventName, @onToolbarNavEvent)
            toolbarViews

        getToolbarOptions: (options) => _.extend({controller: @controller}, options.toolbarOptions or {})

        remove: =>
            delete @controller
            @removeAllSubviews()
            @stopListening(@)
            super

        stateFromTargetName: (targetName)       => targetName
        onToolbarNavEvent: (sender, targetName) -> @setState(@stateFromTargetName(targetName))
        onStateChange: (sender, state)          => @setActiveView(state)

        setActiveView: (state=@currentState) =>
            for own toolbarName, toolbarView of @toolbarViews
                if toolbarName != state
                    toolbarView.setActive(false)
            @toolbarViews[state].setActive(true)


    class EditorColorModeButtonView extends EditorToggleButtonView

        className:      "color-mode-button #{EditorToggleButtonView::className}"
        states:         [ColorMode.WORD, ColorMode.LETTER]
        defaultState:   ColorMode.DEFAULT

        initialize: (options) =>
            super
            @model = options.model
            @editor = options.editor
            @setState(@model.get('colorMode'))
            @listenTo(@model, 'change:colorMode', @onColorModeChange)

        onColorModeChange: (sender, value) => @setState(value)

        remove: =>
            @stopListening(@model)
            delete @model
            delete @editor
            super

        render: =>
            super

        onClick: =>
            super
            @model.set('colorMode', @currentState)




    class ColorToolbarView extends EditorSubToolbarView

        toolbarName: ToolbarEnum.COLOR

        rightSide: [
            viewClass: SquarePickerView,
            viewType: 'palette'
        ]

        onActiveChanged: ->
            canvasView  = @controller.canvasView
            mode        = if @active then CanvasMode.COLOR else canvasView.getDefaultMode()
            canvasView.setMode(mode)

    class ToolbarView extends StatefulToolbarBaseView

        defaultState: TooltipToolbarView::toolbarName

        toolbarClasses: [
            TooltipToolbarView
            ColorToolbarView
        ]

        stateFromTargetName: (targetName) =>
            if targetName == 'back'
                @defaultState
            else
                targetName


    module.exports =
        ToolbarView:            ToolbarView
