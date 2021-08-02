    'use strict'

    {template} = require('./../../../../common/templates')
    {UploadMediumPanel} = require('./../base')
    {MediaLibraryPanelMixin} = require('./base')


    UploadMediumPanelBase = UploadMediumPanel
        .extend(MediaLibraryPanelMixin)

    ## MEDIALIBRARY UPLOAD VIEWS ##
    class UploadPanel extends UploadMediumPanelBase
        title: 'Upload'
        menuName: 'Upload'
        modalTitle: 'Add new medium'
        template: template('./editor/media/library/upload.ejs')

        initialize: (options) =>
            super

        setupEditables: =>
            super
            @listenTo(@uploadView.uploader, 'upload:complete', @onUploadComplete)

        remove: =>
            @stopListening(@uploadView?.uploader?)
            @mediaLibraryPanelMixinCleanup()
            delete @navView
            super

        hide: =>
            super
            @navView.setActive(false)

        show: =>
            super
            @navView.setActive(true)

        isOKAllowed: => @uploadView?.fileUploaded

        onUploadComplete: => @trigger('upload:success', @)


    class UploadSoundPanel extends UploadPanel
        mediaType: 'Sound'
        allowedMimeTypes: ['audio/mpeg', 'audio/mp3']
        modalTitle: 'Upload sound'


    class UploadImagePanel extends UploadPanel
        mediaType: 'Image'
        allowedMimeTypes: ['image/gif', 'image/jpg', 'image/jpeg', 'image/png']
        modalTitle: 'Upload image'


    module.exports =
        UploadPanel: UploadPanel
        UploadSoundPanel: UploadSoundPanel
        UploadImagePanel: UploadImagePanel
