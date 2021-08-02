    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    require('jquery.cookie')
    settings = require('./../settings')
    config = require('./../config')
    {pad, pathJoin} = require('./../common/utils')
    {EventObject} = require('./../common/events')


    class Uploader extends EventObject

        constructor: (options) -> @initialize(options)

        initialize: (options) =>

        upload: (file, location) =>


    class SequentialChunkUploader extends Uploader

        maxBlockSize: 4 * 1024

        initialize: (options) ->
            @maxBlockSize = options.maxBlockSize or @maxBlockSize

        upload: (file, options) =>
            uploadInfo = @_prepareUploadInfo(file, options)
            @_readNextBlock(uploadInfo)
            uploadInfo

        triggerError: (options) =>
            @trigger('upload:error', this, options.uploadInfo, options.message)

        _prepareUploadInfo: (file, options)=>
            fileSize = file.size
            location = options?.location
            if not location? or location == ''
                location = file.name
            uploadInfo =
                file: file
                reader: new FileReader()
                fileSize: fileSize
                location: location
                originalLocation: location
                bytesRead: 0
                bytesUploaded: 0
                currentReadPosition: 0
                blockIds: []
            if fileSize < @maxBlockSize
                uploadInfo.maxBlockSize = fileSize
            else
                uploadInfo.maxBlockSize = @maxBlockSize
            uploadInfo.bytesToRead = fileSize
            if fileSize % uploadInfo.maxBlockSize == 0
                uploadInfo.numberOfBlocks = fileSize / uploadInfo.maxBlockSize
            else
                uploadInfo.numberOfBlocks = parseInt(fileSize / uploadInfo.maxBlockSize, 10) + 1

            uploadInfo.reader.onloadend = (event) =>
                if event.target.readyState == FileReader.DONE
                    buffer = new Uint8Array(event.target.result)
                    success = =>
                        if buffer.length == 0
                            @triggerError
                                uploadInfo: uploadInfo
                                message: 'Invalid length of read bytes'
                            return
                        uploadInfo.bytesUploaded += buffer.length
                        @trigger('upload:change', this, uploadInfo)
                        @_readNextBlock(uploadInfo)
                    failure = =>
                        @triggerError
                            uploadInfo: uploadInfo
                            message: 'Block upload failed'
                    blockId = uploadInfo.blockIds[uploadInfo.blockIds.length - 1]
                    @uploadBlock(uploadInfo, blockId, buffer, success, failure)

            uploadInfo

        _readNextBlock: (uploadInfo) =>
            currentPos = uploadInfo.currentReadPosition
            blockSize = _.min([uploadInfo.bytesToRead, uploadInfo.maxBlockSize])
            if blockSize > 0
                fileContent = uploadInfo.file.slice(currentPos, currentPos + blockSize)
                uploadInfo.blockIds.push(@getBlockId(uploadInfo.blockIds.length))
                # asynchronously read next block
                uploadInfo.reader.readAsArrayBuffer(fileContent)
                uploadInfo.bytesRead += blockSize
                uploadInfo.bytesToRead -= blockSize
                uploadInfo.currentReadPosition += blockSize
                @trigger('upload:change', this, uploadInfo)
            else
                success = =>
                    @trigger('upload:complete', this, uploadInfo)
                failure = =>
                    @triggerError
                        uploadInfo: uploadInfo
                        message: 'Upload finalization failed'
                @commitBlocks(uploadInfo, uploadInfo.blockIds, success, failure)

        getBlockId: (blockIndex) =>
            # override in subclass.
            "block-#{blockIndex}"

        uploadBlock: (uploadInfo, blockId, buffer, success, failure) =>
            # override in subclass. this function should send the data to
            # specified location and call success callback if upload was
            # successful or failure callback if upload failed.
            console.log("uploading block #{blockId} of #{buffer.length} bytes to #{uploadInfo.location}")
            success()

        commitBlocks: (uploadInfo, blockIds, success, failure) =>
            # override in subclass. this function should commit all previously
            # uploaded blocks and call success callback if operation was
            # successful, and in other case call the failure callback.
            console.log("commiting #{blockIds.length} block(s) uploaded to #{uploadInfo.location}")
            success()


    class AjaxUploader extends SequentialChunkUploader

        initialize: (options) ->
            super
            @config = options?.config or settings.blobStorage

        makeRequest: (requestInfo, success, failure) =>
            @makeAjaxRequest(requestInfo, success, failure)

        makeAjaxRequest: (requestInfo, success, failure) =>
            $.ajax
                url: requestInfo.url
                type: requestInfo.method
                data: requestInfo.data
                processData: false
                beforeSend: (xhr) =>
                    @setHeaders(xhr, requestInfo)
                    @signRequest(xhr, requestInfo)
                success: (data, status) -> success(data)
                error: (xhr, desc, err) -> failure()

        setHeaders: (xhr, requestInfo) =>
            for key, value of requestInfo.headers
                xhr.setRequestHeader(key, value)

        signRequest: (xhr, requestInfo) =>
            # override in subclass.
            console.log("signing the xhr request #{requestInfo.url}")


    class DjangoUploader extends AjaxUploader
        maxBlockSize: 16 * 1024

        initialize: (options) ->
            super
            @allowedMimeTypes = options?.allowedMimeTypes
            @urlMethods = options?.urlMethods or settings.urlMethods
            @urlRoot = options?.urlRoot

        getBaseUploadUrl: -> @urlRoot or config.getUrlRoot(settings.apiResourceNames.blobs)

        getUrl: (uploadInfo) => uploadInfo.mediumUrl

        upload: (file, options) =>
            uploadInfo = @_prepareUploadInfo(file, options)
            uploadInfo.mediaType = options.mediaType or 'Undefined'
            if @allowedMimeTypes?
                if not (uploadInfo.file.type in @allowedMimeTypes)
                    @triggerError
                        uploadInfo: uploadInfo
                        message: 'This file type is not allowed here'
                    return
            success = =>
                @_readNextBlock(uploadInfo)
            failure = =>
                @triggerError
                    uploadInfo: uploadInfo
                    message: 'Upload init failed'
            @initUpload(uploadInfo, success, failure)
            uploadInfo

        initUpload: (uploadInfo, success, failure) =>
            info =
                method: 'POST'
                headers:
                    'Content-Type': 'application/json'
                    'X-CSRFToken': $.cookie('csrftoken')
                url: @getBaseUploadUrl()
                data: JSON.stringify
                    name: uploadInfo.location
                    type: uploadInfo.mediaType.toLowerCase()
                    mime_type: uploadInfo.file.type

            oldSuccess = success
            success = (result) ->
                uploadInfo.mediumId = result.id
                uploadInfo.mediumUrl = result.url
                uploadInfo.uploadInitResponse = result
                oldSuccess()

            @makeRequest(info, success, failure)

        signRequest: (xhr, requestInfo) =>

        getBlockId: (blockIndex) -> "#{blockIndex}"

        uploadBlock: (uploadInfo, blockId, buffer, success, failure) =>
            info = {}
            info.headers =
                'Content-Length': buffer.length
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                'X-CSRFToken': $.cookie('csrftoken')
                'X-Upload-Type': 'block'
                'X-Block-ID': blockId
            info.method = 'PATCH'
            info.data = buffer
            info.dataIsUint8Array = true

            info.url = pathJoin(@getBaseUploadUrl(), uploadInfo.mediumId, '/')
            @makeRequest(info, success, failure)

        commitBlocks: (uploadInfo, blockIds, success, failure) =>
            data = JSON.stringify
                blocks: uploadInfo.blockIds

            info = {}
            info.headers =
                'Content-Length': data.length
                'Content-Type': 'application/json'
                'X-CSRFToken': $.cookie('csrftoken')
                'X-Upload-Type': 'blocklist'
            info.method = 'PATCH'
            info.data = data
            info.url = pathJoin(@getBaseUploadUrl(), uploadInfo.mediumId, '/')
            @makeRequest(info, success, failure)


    module.exports =
        LanguageGardenUploader: DjangoUploader
