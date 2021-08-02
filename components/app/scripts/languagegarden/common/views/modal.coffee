    'use strict'

    _ = require('underscore')
    Backbone = require('backbone')
    $ = require('jquery')
    require('backbone.bootstrap-modal')
    {RenderableView} = require('./renderable')
    {RenderSubviewMixin} = require('./renderable')


    MultiContentBootstrapModalBase = Backbone.BootstrapModal
        .extend(RenderSubviewMixin)


    class MultiContentBootstrapModal extends MultiContentBootstrapModalBase

        delayedOpenStarted: false

        subviews: {
            # selector: view
            # selector: [view, ]
        }

        initialize: (options) =>
            super
            @subviews = options.subviews

        render: =>
            super
            @renderSubview(@subviews) if @subviews
            @

        ###Call this any time before open to show a progress bar indicating
        that the modal is getting ready.

        ###
        delayedOpenStart: =>
            $('body').modalmanager('loading');
            @delayedOpenStarted = true

        open: =>
            @delayedOpenStarted = false
            super

        close: =>
            if @delayedOpenStarted
                $('body').modalmanager('removeLoading')
            super

        layout: => @$el.modal('layout')


    ### View that can be shown as a boostrap modal. ###
    class ModalView extends RenderableView

        title: 'Menu'
        css: 'modal fade container'
        modalClass: MultiContentBootstrapModal
        delayModalOpen: false

        initialize: (options) =>
            super
            @modalClass = options.modalClass or @modalClass
            @extra_css = options.extra_css or @extra_css
            @modalOptions = options?.modalOptions

        getModalOptions: ->
            css = @css
            css = "#{@css} #{@extra_css}" if @extra_css

            modalOptions =
                title: @title
                content: @
                allowCancel: true
                className: css

            if @modalOptions?
                _.extend(modalOptions, @modalOptions)

            modalOptions

        createModal: => new @modalClass(@getModalOptions())

        onModalDelayedOpenStart: =>
            @modal.open()

        openModal: =>
            if @delayModalOpen
                @modal.delayedOpenStart()
                @onModalDelayedOpenStart()
            else
                @modal.open()

        closeModal: =>
            @modal?.close()

        hide: => @closeModal()

        show: =>
            @modal = @createModal()
            @openModal()

        updateModalTitle: (title) =>
            @$modalTitleEl ?= @modal.$('.modal-title')
            @$modalTitleEl.html(title)


    module.exports =
        ModalView: ModalView
        MultiContentBootstrapModal: MultiContentBootstrapModal
