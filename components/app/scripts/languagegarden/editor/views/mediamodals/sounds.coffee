    'use strict'

    _ = require('underscore')
    {template} = require('./../../../common/templates')
    baseModals = require('./base')

    {
        EditablePanel,
        OKCancelModalView,
        CloseModalView,
        UploadMediumPanel,
    } = baseModals


    EditUrlsPanel = class extends EditablePanel

        title: 'Add URLs'
        menuName: 'Audio URLs'
        template: template('./editor/sounds/panels/urls.ejs')

        setupEditables: =>
            @setupEditable('.input-url', 'text', 'url')
            @setupEditable('.input-fallback-url', 'text', 'fallbackUrl')

        isOKAllowed: =>
            testFun = (attrName) =>
                val = @model.get(attrName)
                val? and val.length > 0
            _.all(['url'], testFun)

        getModelAttribute: (name) =>
            if name == 'fallbackUrl'
                super('urls')?[0]
            else
                super

        setModelAttribute: (name, value, options) =>
            if name == 'fallbackUrl'
                if value? and value != ''
                    urlsValue = [value]
                else
                    urlsValue = []
                super('urls', urlsValue, options)
            else
                super


    UploadSoundPanel = class extends UploadMediumPanel
        mediaType: 'Sound'
        allowedMimeTypes: ['audio/mpeg', 'audio/mp3']


    AddSoundView = class extends OKCancelModalView

        title: 'Add Sound'
        template: template('./editor/images/main.ejs')
        extra_css: 'add-sound-modal'

        panels: [
            EditUrlsPanel,
            UploadSoundPanel,
        ]

        onSuccess: =>
            @editor.model.addMedium(@model)

        isOKAllowed: =>
            testFun = @currentPanel.view.isOKAllowed
            if testFun? then testFun() else true


    EditSoundView = class extends CloseModalView

        title: 'Edit Sound'
        template: template('./editor/images/main.ejs')
        extra_css: 'edit-sound-modal'

        panels: [
            EditUrlsPanel,
            UploadSoundPanel,
        ]

        onSuccess: =>

        isOKAllowed: =>
            testFun = @currentPanel.view.isOKAllowed
            if testFun? then testFun() else true



    module.exports =
        AddSoundView: AddSoundView
        EditSoundView: EditSoundView
