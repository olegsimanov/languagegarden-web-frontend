    'use strict'

    _ = require('underscore')
    {template} = require('./../../common/templates')
    {RenderableView} = require('./../../common/views/renderable')
    {LanguageGardenUploader} = require('./../uploaders')


    module.exports =
        UploaderView: class UploaderView extends RenderableView
            template: template('./editor/media/uploader.ejs')
            tagName: 'div'
            className: "uploader"
            events:
                'change .file': 'onFileChange'

            initialize: (options) =>
                super
                @fileUploaded = false
                @fileUploading = false
                @errorOccured = false
                @uploadInfo = null
                @mediaType = options?.mediaType
                @allowedMimeTypes = options?.allowedMimeTypes
                @editor = options?.editor
                @uploader = new LanguageGardenUploader
                    allowedMimeTypes:  @allowedMimeTypes
                @listenTo(@uploader, 'upload:change', @onUploadChange)
                @listenTo(@uploader, 'upload:error', @onUploadError)
                @listenTo(@uploader, 'upload:complete', @onUploadComplete)

            remove: =>
                delete @editor
                @stopListening(@model)
                @stopListening(@uploader)
                super

            getRenderContext: (ctx={}) ->
                newCtx = super
                newCtx._ = _
                newCtx.fileUploaded = @fileUploaded
                newCtx.fileUploading = @fileUploading
                newCtx.errorOccured = @errorOccured
                newCtx.errorMessage = @errorMessage
                newCtx.uploadInfo = @uploadInfo
                newCtx

            onFileChange: (event) =>
                file = event.target.files[0]
                options =
                    mediaType: @mediaType
                @errorOccured = false
                @errorMessage = ''
                @uploadInfo = @uploader.upload(file, options)
                @fileUploading = true
                @fileUploaded = false

            onUploadChange: (uploader, uploadInfo) =>
                if uploadInfo != @uploadInfo
                    return
                @render()

            onUploadComplete: (uploader, uploadInfo) =>
                if uploadInfo != @uploadInfo
                    return
                @fileUploading = false
                @fileUploaded = true
                @model.set('url', @uploader.getUrl(uploadInfo))
                @render()

            onUploadError: (uploader, uploadInfo, errorMessage) =>
                # only perform test if the upload() returned non null uploadInfo
                if @uploadInfo? and uploadInfo != @uploadInfo
                    return
                @fileUploading = false
                @errorOccured = true
                @errorMessage = errorMessage
                @render()
