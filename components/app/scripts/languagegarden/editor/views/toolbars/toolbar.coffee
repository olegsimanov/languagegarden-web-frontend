    'use strict'

    _                           = require('underscore')


    {ButtonView}                = require('./buttons')
    {SelectionButtonGroupView}  = require('./selection')
    {SquarePickerView}          = require('./square')

    {RenderableView}            = require('./../renderable')
    {template}                  = require('./../templates')
    {slugify}                   = require('./../../utils')


    {StatefulToolbarView}       = require('./../../views/toolbars/stateful')
    {
        SaveAndGoToNavigatorAction
        DiscardAndGoToNavigatorAction
    }                           = require('./../../actions/navigation')
    {CanvasMode}                = require('./../../constants')

    settings                    = require('./../../../settings')

    NavButtonPrototype =

        navTarget: null
        eventName: null

        triggerToolbarNavEvent:                          -> @trigger(@eventName, @, @navTarget)

        getNavButtonClass: (navTarget=@navTarget)   -> "toolbar-button-#{ slugify(@navTarget) }"
        getNavEventName: (navTarget=@navTarget)     -> "toolbarnav:#{ slugify(navTarget) }"

        initializeNavButton: (options) ->
            @setOptions(options, ['navTarget'], true)
            @setOptions(options, [['eventName', @getNavEventName()]], true)
            @customClassName = @getNavButtonClass()

        navButtonOnClick: ->
            if not @isEnabled()
                return true
            @triggerToolbarNavEvent()


    class NavButtonView extends ButtonView.extend(NavButtonPrototype)

        initialize: (options) ->
            @initializeNavButton(options)
            super

        onClick: (e)    => @navButtonOnClick()
        isEnabled:      -> true


    class BackButtonView extends NavButtonView

        navTarget:              'back'
        getNavButtonClass:      -> "#{super} icon icon_back"


    BaseToolbarView = class extends RenderableView

        toolbarViewAnchors:         {}
        toolbarName:                'toolbar-name-missing'
        fallbackActionViewClass:    ButtonView

        getToolbarViewAnchors: -> @toolbarViewAnchors

        initialize: (options) ->
            @active = true

            super

            if settings.isMobile
                @mobileInit()
            else
                @desktopInit()

            @initSubviews()

        mobileInit: ->

        desktopInit: ->

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
                when 'settingsButton'
                    args =
                        controller:                 @controller
                        editor:                     @controller.canvasView
                        modalView:                  @settingsView
                when 'label'
                    args =
                        controller:                 @controller
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

        getToolbarCssClass: -> "toolbar-#{ slugify(@toolbarName) }"

        setActive: (value) ->
            if @active == value
                return

            @active = value
            @updateVisibility()
            @onActiveChanged()

        updateVisibility: -> @$('.toolbar').toggleClass('toolbar_active', @active)

        onActiveChanged: ->


    class EditorToolbarView extends BaseToolbarView

        template: template('./common/toolbars/navigator.ejs')

        toolbarViewAnchors:
            '.station-navigator':           'plantNavMenu'
            '.toolbar__section_mid':        'contentMenu'
            '.toolbar__section_right':      'controlButtonsMenu'

        desktopInit: ->

        remove: ->
            super


    class EditorSubToolbarView extends EditorToolbarView

        template: template('./common/toolbars/container.ejs')

        backNav: [
            viewType: 'navbutton'
            viewClass: BackButtonView,
        ]

        toolbarViewAnchors:
            '.toolbar__section_left':   'backNav'
            '.toolbar__section_mid':    'contentMenu'
            '.toolbar__section_right':  'rightSide'


    class PaletteNavButtonView extends NavButtonView

        getNavButtonClass: -> "#{super} icon icon_palette"

        initialize: (options) ->
            super
            @setOptions(options, ['controller'], true)
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

    ToolbarEnum =
        NAVIGATION:     'navigation'
        BUILDER:        'builder'
        COLOR:          'color'


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

    class ColorToolbarView extends EditorSubToolbarView

        toolbarName: ToolbarEnum.COLOR

        rightSide: [{viewClass: SquarePickerView, viewType: 'palette'}]

        onActiveChanged: ->
            canvasView  = @controller.canvasView
            mode        = if @active then CanvasMode.COLOR else canvasView.getDefaultMode()
            canvasView.setMode(mode)


    class ToolbarView extends StatefulToolbarView

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
