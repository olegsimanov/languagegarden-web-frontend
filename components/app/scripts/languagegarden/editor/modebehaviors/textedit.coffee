    'use strict'

    {ModeBehavior} = require('./../../common/modebehaviors/base')
    LetterSelectBehavior = require('./../letterbehaviors/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior = require('./../letterbehaviors/edit').EditBehavior
    {TextEditSelectBehavior} = require('./../mediabehaviors/textedit')
    MediumEditBehavior = require('./../mediabehaviors/edit').EditBehavior
    {MediumType} = require('./../../common/constants')


    class TextEditBehavior extends ModeBehavior
        mediaClasses: [
            TextEditSelectBehavior,
            MediumEditBehavior,
        ]
        boundLettersClasses: [
            LetterSelectBehavior,
            LetterEditBehavior,
        ]
        middleLettersClasses: [
            LetterSelectBehavior,
            LetterEditBehavior,
        ]

        getTextMediaViews: (onlySelected=false) =>
            views = []
            for view in @parentView.getMediaViews(MediumType.TEXT)
                if onlySelected and not view.isSelected()
                    continue
                views.push(view)
            views

        onModeEnter: (oldMode) =>
            super
            for view in @getTextMediaViews()
                view.startEdit() if view.shouldEnterEditMode

        onModeLeave: (newMode) =>
            for view in @getTextMediaViews()
                view.shouldEnterEditMode = false
                view.finishEdit()
            super


    module.exports =
        TextEditBehavior: TextEditBehavior
