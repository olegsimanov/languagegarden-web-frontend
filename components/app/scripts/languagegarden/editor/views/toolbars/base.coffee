    'use strict'

    _ = require('underscore')
    settings = require('./../../../settings')
    {RenderableView} = require('./../renderable')
    {slugify} = require('./../../../common/utils')
    {DivButton} = require('./../buttons')

    {template} = require('./../../../common/templates')
    {ToolbarBackButton} = require('./../../views/toolbars/navbuttons')


    BaseToolbar = class extends RenderableView

        # map for selector: <list of viewData>
        toolbarViewAnchors: {}
        toolbarName: 'toolbar-name-missing'
        fallbackActionViewClass: DivButton

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
                        controller: @controller
                        editor: @controller.canvasView
                when 'button'
                    args =
                        controller: @controller
                        editor: @controller.canvasView
                when 'buttongroup'
                    args =
                        controller: @controller
                        canvasView: @controller.canvasView
                        model: @controller.model
                        shouldAppendToContainer: false
                when 'palette'
                    args =
                        editor: @controller.canvasView
                        model: @controller.canvasView.editorPalette
                        shouldAppendToContainer: false
                when 'settingsButton'
                    args =
                        controller: @controller
                        editor: @controller.canvasView
                        modalView: @settingsView
                when 'label'
                    args =
                        controller: @controller
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

    class EditorToolbar extends BaseToolbar

        template: template('./common/toolbars/navigator.ejs')

        toolbarViewAnchors:
            '.station-navigator': 'plantNavMenu'
            '.toolbar__section_mid': 'contentMenu'
            '.toolbar__section_right': 'controlButtonsMenu'

        desktopInit: ->

        remove: ->
            super


    class EditorSubToolbar extends EditorToolbar

        template: template('./common/toolbars/container.ejs')

        backNav: [
            {viewClass: ToolbarBackButton, viewType: 'navbutton'}
        ]

        toolbarViewAnchors:
            '.toolbar__section_left': 'backNav'
            '.toolbar__section_mid': 'contentMenu'
            '.toolbar__section_right': 'rightSide'


    module.exports =
        EditorToolbar: EditorToolbar
        EditorSubToolbar: EditorSubToolbar
