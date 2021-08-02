    'use strict'

    _ = require('underscore')
    {template} = require('./../../../common/templates')
    {
        EditablePanel
        OKCancelModalView
        CloseModalView
        UploadMediumPanel
    } = require('./base')


    class AddUrlPanel extends EditablePanel

        title: 'Add URL'
        menuName: 'URL'
        template: template('./editor/images/panels/url.ejs')

        setupEditables: =>
            @setupEditable('.input-url', 'text', 'url')

        isOKAllowed: =>
            url = @model.get('url')
            url? and url.length > 0


    class UploadImagePanel extends UploadMediumPanel
        mediaType: 'Image'
        allowedMimeTypes: ['image/gif', 'image/jpg', 'image/jpeg', 'image/png']


    class AddImageView extends OKCancelModalView
        title: 'Add Image'
        template: template('./editor/images/main.ejs')
        extra_css: 'add-image-modal'

        panels: [
            AddUrlPanel,
            UploadImagePanel,
        ]

        onSuccess: =>
            @editor.model.addMedium(@model)

        isOKAllowed: =>
            testFun = @currentPanel.view.isOKAllowed
            if testFun? then testFun() else true


    class EditImageView extends CloseModalView
        title: 'Edit image'
        template: template('./editor/images/main.ejs')
        extra_css: 'edit-image-modal'

        panels: [
            AddUrlPanel,
            UploadImagePanel,
        ]

        onSuccess: =>

        isOKAllowed: =>
            testFun = @currentPanel.view.isOKAllowed
            if testFun? then testFun() else true


    module.exports =
        AddImageView: AddImageView
        EditImageView: EditImageView
