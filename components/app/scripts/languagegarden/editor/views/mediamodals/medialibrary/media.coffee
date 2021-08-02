    'use strict'

    _ = require('underscore')
    {template, templateWrapper} = require('./../../../../common/templates')
    {
        MediaLibraryViewBase
        MediaLibraryPanelBase
        MediaLibraryEditPanel
    } = require('./base')
    {UploadImagePanel, UploadSoundPanel} = require('./upload')
    {SearchPanel, CloseOnSelectSearchPanel} = require('./search')
    {EditSearchPanel, EventedSearchPanel} = require('./search')
    mediumMetaModels = require('./../../../models/mediummeta')
    plantListModels = require('./../../../../common/models/plantlists')


    # IMAGE PREVIEW PANEL
    class MediaLibraryPreviewPanel extends MediaLibraryPanelBase
        template: templateWrapper(-> 'missing template')
        menuName: 'Preview'
        modalTitle: 'Preview'
        detailsPanelIndex: 0

        initialize: (options) =>
            super
            @listenTo(@parent, 'success:upload', @onPanelSuccess)
            @listenTo(@parent, 'success:search', @onPanelSuccess)
            @listenTo(@parent, 'success:preview', @onSuccess)
            @listenTo(@parent, 'remove:preview', @onRemove)

        onPanelSuccess: (panel) =>
            @parent.setActivePanel(@parent.getViewPanelData(@))
            @render()

        remove: ->
            @stopListening(@parent)
            super

        isOKAllowed: => @model.get('url')?

        onSuccess: =>
            if not @parent.originalModel.collection?
                @parent.originalModel.set(@model.toJSON())
                if @parent.insertCollection?
                    @parent.insertCollection.add(@parent.originalModel)
            else
                oldVal = @parent.originalModel.get('url')
                if oldVal != @model.get('url')
                    @parent.originalModel.set('url', @model.get('url'))

            if @parent.saveAfterSuccess
                @timeline.saveModel()

        isRemoveAllowed: => @parent.originalModel.collection?

        onRemove: (panel) =>
            if @isRemoveAllowed()
                @editor.model.removeMedium(@parent.originalModel)

        getNavViews: ->
            super
            if not @model.get('url')
                _.each(@navViews, (v) -> v.hide())
            @navViews


    class MediaLibraryImagePreviewPanel extends MediaLibraryPreviewPanel
        template: template('./editor/media/library/image_preview.ejs')


    class MediaLibrarySoundPreviewPanel extends MediaLibraryPreviewPanel
        template: template('./editor/media/library/sound_preview.ejs')


    class ForwardingMediaLibraryView extends MediaLibraryViewBase

        initialize: (options) =>
            super
            @listenTo(
                @getPanelByName('search').view, 'itemselected',
                @forwardPanelSuccess
            )
            @listenTo(
                @getPanelByName('upload').view, 'upload:success',
                @forwardPanelSuccess
            )

        forwardPanelSuccess: (panel) =>
            @trigger("success:#{@getViewPanelData(panel).panelName}", panel)


    class MediaLibraryView extends ForwardingMediaLibraryView

        initialize: (options) =>
            if not options.model? or not options.model.get('url')
                @defaultPanelName = 'search'
            super
            @listenTo(@, 'change:panel success:search', @onPanelChange)

        onPanelChange: => @modal.layout()


    # MEDIALIBRARY SELECTING VIEWS
    class ImageMediaLibraryView extends MediaLibraryView

        mediumMetaCollectionCls: mediumMetaModels.ImageMediumMetaCollection

        panels: [
            {panelName: 'preview', panelClass: MediaLibraryImagePreviewPanel}
            {panelName: 'search', panelClass: EventedSearchPanel}
            {panelName: 'upload', panelClass: UploadImagePanel}
        ]


    class SoundMediaLibraryView extends MediaLibraryView

        mediumMetaCollectionCls: mediumMetaModels.SoundMediumMetaCollection

        panels: [
            {panelName: 'preview', panelClass: MediaLibrarySoundPreviewPanel}
            {panelName: 'search', panelClass: EventedSearchPanel}
            {panelName: 'upload', panelClass: UploadSoundPanel}
        ]


    module.exports =
        ImageMediaLibraryView: ImageMediaLibraryView
        SoundMediaLibraryView: SoundMediaLibraryView
