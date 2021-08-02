    'use strict'

    _ = require('underscore')
    $ = require('jquery')
    {Menu, Panel} = require('./../../../common/views/menu')
    {template} = require('./../../../common/templates')
    {UploaderView} = require('./../uploaders')


    class EditablePanel extends Panel

        initialize: (options) =>
            super
            @setPropertyFromOptions(options, 'model',
                                    default: @parent.model
                                    required: true)
            @setPropertyFromOptions(options, 'canvasView',
                                    default: @parent.canvasView or @parent.editor
                                    required: true)
            @setPropertyFromOptions(options, 'timeline',
                                    default: @parent.timeline
                                    required: true)
            @editor = @canvasView

        remove: =>
            @stopListening(@model)
            delete @model
            delete @canvasView
            delete @timeline
            delete @editor
            super

        setupEditables: =>

        setupEditable: (selector, type, modelAttribute, options) =>
            @editables ?= {}
            @editables[modelAttribute] = [selector, type]

            $item = @$(selector)
            $item.data('model-attribute', modelAttribute)

            opts =
                mode: 'inline'
                emptyclass: 'muted'
                emptytext: 'Click to change'
                unsavedclass: ''
                type: type
                value: @getModelAttribute(modelAttribute)
            opts = _.extend(opts, options) if options?

            $item.editable(opts)

            @listenTo(@model, "change:#{modelAttribute}", (sender, value) =>
                @modelChanged(sender, value, modelAttribute))

            $item.on('save', @onEditableSave)
            $item

        modelChanged: (sender, value, modelAttribute) ->
            toUpdate = @editables[modelAttribute]
            if toUpdate?
                [selector, type] = toUpdate
                if type == 'text'
                    @$(selector).editable('setValue', value)
                else
                    console.log("Missing model changed for input type: #{type}")

        getModelAttribute: (name) => @model.get(name)

        setModelAttribute: (name, value, options) =>
            @model.set(name, value, options)

        onEditableSave: (e, params) =>
            @setModelAttribute($(e.target).data('model-attribute'),
                               params.newValue)

        render: (options) =>
            super
            @setupEditables()
            @

        isOKAllowed: => true


    class UploadMediumPanel extends EditablePanel

        title: 'Upload file'
        menuName: 'File upload'
        template: template('./editor/media/panels/upload.ejs')
        mediaType: 'MissingMediaType'
        allowedMimeTypes: null

        remove: =>
            @uploadView?.remove()
            super

        setupEditables: =>
            @uploadView = new UploaderView
                editor: @editor
                mediaType: @mediaType
                allowedMimeTypes: @allowedMimeTypes
                model: @model
                el: this.$('.uploader')
            @uploadView.render()

        isOKAllowed: =>
            url = @model.get('url')
            url? and url.length > 0


    class CloseModalView extends Menu
        template: template('./editor/images/main.ejs')

        initialize: (options) =>
            options.modalOptions ?= {}
            options.modalOptions.allowOK = false
            options.modalOptions.allowCancel = true
            options.modalOptions.cancelText = 'Close'
            @editor = options.editor
            @model = options.model
            super

        show: =>
            super
            @modal.on('cancel', @onClose)

        remove: =>
            @modal.off('cancel')
            @stopListening(@model)
            super

        onClose: =>
            @onSuccess()

        onSuccess: =>


    class OKCancelModalView extends Menu
        template: template('./editor/images/main.ejs')

        initialize: (options) =>
            options.modalOptions ?= {}
            options.modalOptions.allowOK = true
            options.modalOptions.okText = 'OK'
            options.modalOptions.allowCancel = true
            options.modalOptions.cancelText = 'Cancel'
            @editor = options.editor
            @model = options.model
            super
            @onSuccess = options.onSuccess if options.onSuccess?
            @listenTo(@model, 'change', @onModelChange)

        remove: =>
            @stopListening(@model)
            super

        getJQueryModal: => @modal.$el

        isOKAllowed: => true

        updateOKButton: =>
            @getJQueryModal()
                .find('.ok')
                .toggleClass('disabled', !@isOKAllowed())
                .off('click')
                .on('click', @onOKClicked)

        onModelChange: =>
            @updateModalButtons()

        show: =>
            super
            @updateModalButtons()

        onOKClicked: (event) =>
            if @isOKAllowed()
                @onSuccess()
            else
                event.preventDefault()
                event.stopImmediatePropagation()

        onSuccess: =>

        updateModalButtons: =>
            @updateOKButton()


    class OKRemoveCancelModalView extends OKCancelModalView

        initialize: (options) ->
            options.modalOptions ?= {}
            options.modalOptions.allowRemove = true
            options.modalOptions.removeText = 'Remove'
            super

        isRemoveAllowed: => true

        updateRemoveButton: =>
            @getJQueryModal()
                .find('.remove')
                .toggleClass('disabled', !@isRemoveAllowed())
                .off('click')
                .on('click', @onRemoveClicked)

        updateModalButtons: =>
            super
            @updateRemoveButton()

        onRemoveClicked: (event) =>
            if @isRemoveAllowed()
                @onRemove()
                @hide()
            else
                event.preventDefault()
                event.stopImmediatePropagation()

        onRemove: =>


    module.exports =
        EditablePanel: EditablePanel
        UploadMediumPanel: UploadMediumPanel
        CloseModalView: CloseModalView
        OKCancelModalView: OKCancelModalView
        OKRemoveCancelModalView: OKRemoveCancelModalView
