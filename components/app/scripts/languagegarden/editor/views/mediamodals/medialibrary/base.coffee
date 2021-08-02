    'use strict'

    _ = require('underscore')
    {template} = require('./../../../../common/templates')
    {OKRemoveCancelModalView} = require('./../base')
    {EditablePanel} = require('./../base')
    {
        BootstrapButtonView
    } = require('./../../../../common/views/bootstrap/buttons')


    class MenuNavView extends BootstrapButtonView

        onClick: (e) =>
            e.preventDefault()
            @trigger('click', @, @panel)

        initialize: (options) =>
            super
            @panel = options.panel


    MediaLibraryPanelMixin =

        getNavViews: ->
            if not @navView?
                @navView = new MenuNavView
                    text: @menuName
                    panel: @
            @navViews ?= []
            @navViews.push(@navView)
            @navViews

        mediaLibraryPanelMixinCleanup: ->
            delete @navView
            delete @navViews


    MediaLibraryPanelBaseInterface = EditablePanel
        .extend(MediaLibraryPanelMixin)


    ###Base class for media library panels.
    Can create a navigation subview that has correct show/hide events setup.
    ###
    class MediaLibraryPanelBase extends MediaLibraryPanelBaseInterface

        show: =>
            super
            @navView.setActive(true)
            @navView.show()

        hide: =>
            super
            @navView.setActive(false)

        remove: =>
            @mediaLibraryPanelMixinCleanup()
            super


    class MediaLibraryViewBase extends OKRemoveCancelModalView

        title: 'Media library'
        modalTemplate: template('./editor/media/library/modal.ejs')
        template: template('./editor/media/library/main.ejs')
        extra_css: 'media-library-modal'
        modalNavContainerSelector: '.modal-top-bar'
        searchLimit: 6

        panels: []

        initialize: (options) =>

            # operate on a copy of the model
            @setPropertyFromOptions(options, 'insertCollection')
            @setPropertyFromOptions(options, 'saveAfterSuccess', default: false)
            @originalModel = options.model
            modelClass = options.model.constructor
            if modelClass.fromJSON?
                modelFactory = modelClass.fromJSON
            else
                modelFactory = (attrs, options) =>
                    new modelClass(attrs, options)

            options.model = modelFactory(options.model.toJSON())

            if options.mediumMetaCollectionCls?
                @mediumMetaCollectionCls = options.mediumMetaCollectionCls

            @mediumMetaCollection = options.mediumMetaCollection
            @mediumMetaCollection ?= new @mediumMetaCollectionCls(
                [], limit: @searchLimit)

            super

            @searchLimit = options.searchLimit if options.searchLimit?

            subviews = {}
            subviews[@modalNavContainerSelector] = @navViews

            args =
                template: @modalTemplate.render
                subviews: subviews

            @modalOptions = _.extend(@modalOptions or {}, args)

        initializeNav: ->
            @navViews = _.flatten(_.map(
                @panelDataOrdered, (pd) -> pd.view.getNavViews()
            ))
            _.each @navViews, (view) => @listenTo(view, 'click', @onNavClick)
            @navViews

        renderNav: => @openDefaultPanel()

        onNavClick: (nav, panelView) =>
            @setActivePanel(@getViewPanelData(panelView))

        setActivePanel: (panel) =>
            if panel.view.isShown
                return

            _.each(@panelDataOrdered, @hidePanel)

            @showPanel(panel)

            @updateModalTitle(panel.view.modalTitle)
            super
            @updateModalButtons()

        hidePanel: (panel) => panel.view.hide()

        showPanel: (panel) =>
            if not _.result(panel.view, 'isRendered')
                @$panelContent.append(panel.view.render().$el)
            panel.view.show()

        remove: ->
            for view in @navViews
                @stopListening(view)
            delete @mediumMetaCollection
            delete @navViews
            delete @topbarView
            super

        isOKAllowed: =>
            testFun = @currentPanel?.view.isOKAllowed
            if testFun? then testFun() else true

        isRemoveAllowed: =>
            testFun = @currentPanel?.view.isRemoveAllowed
            if testFun? then testFun() else false

        onSuccess: =>
            @trigger("success:#{@currentPanel.panelName}", @currentPanel)

        onRemove: =>
            @trigger("remove:#{@currentPanel.panelName}", @currentPanel)

        onModalDelayedOpenStart: =>
            # show modal on fetch complete
            @listenToOnce(
                @mediumMetaCollection, 'reset:success reset:error', =>
                    @modal.open()
            )
            @mediumMetaCollection.fetch()

        delayModalOpen: true


    class MediaLibraryEditPanel extends MediaLibraryPanelBase
        template: template('./editor/media/library/edit.ejs')
        menuName: 'Details'
        modalTitle: 'Details'

        setupEditables: =>
            @setupEditable(
                'a#media-library-edit-panel-input-url', 'text', 'url',
                {disabled: true}
            )

        isOKAllowed: => false


    module.exports =
        MediaLibraryViewBase: MediaLibraryViewBase
        MediaLibraryPanelBase: MediaLibraryPanelBase
        MediaLibraryPanelMixin: MediaLibraryPanelMixin
        MediaLibraryEditPanel: MediaLibraryEditPanel
