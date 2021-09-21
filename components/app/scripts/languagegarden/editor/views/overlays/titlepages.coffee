    'use strict'

    _ = require('underscore')
    {template} = require('./../../../common/templates')
    {RenderableView} = require('./../../../common/views/renderable')
    {
        TitleImageView
        TitlePageOverlay
    } = require('./../../../common/views/overlays/titlepages')


    class EditorTitleView extends RenderableView
        template: template('./editor/titlepages/title.ejs')
        className: 'title-page__title-container title-page__title-form title-form'
        tagName: 'form'
        events:
            'submit': 'onSubmit'
            'click .title-form__caption': 'onTitleCaptionClick'
            'blur .title-form__field': 'onTitleFieldBlur'

        onModelBind: ->
            @listenTo(@model, 'change:title', @invalidate)

        getModelTitle: -> @model.get('title')

        setModelTitle: (newTitle) ->
            @model.set('title', newTitle)
            @model.save()

        getRenderContext: ->
            ctx = super
            ctx.title = @getModelTitle()
            ctx

        renderTemplate: ->
            super
            @$titleFieldContainer = @$('.title-form__field-container')
            @$titleField = @$('.title-form__field')
            @$titleCaption = @$('.title-form__caption')

        onSubmit: (event) ->
            event.preventDefault()
            @$titleField.blur()

        onTitleCaptionClick: (event) ->
            event.preventDefault()
            prevTitleName = @getModelTitle()
            @$titleCaption.hide()
            @$titleFieldContainer.show()
            @$titleField.val(prevTitleName).focus().select()

        onTitleFieldBlur: (event) ->
            newTitle = @$titleField.val()
            prevTitleName = @getModelTitle()

            @$titleFieldContainer.hide()

            if not newTitle or prevTitleName == newTitle
                @$titleCaption.show()
                return
            @$titleCaption.text(newTitle).show()
            @setModelTitle(newTitle)


    class EditorTitlePageOverlay extends TitlePageOverlay
        titleViewClass: EditorTitleView


    module.exports =
        TitlePageOverlay: EditorTitlePageOverlay
