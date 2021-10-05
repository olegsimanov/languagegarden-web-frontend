    'use strict'

    {ModeBehavior}              = require('./base')
    {MediumType}                = require('./../../constants')
    LetterSelectBehavior        = require('./../../behaviors/letter/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior          = require('./../../behaviors/letter/edit').EditBehavior


    class TextEditBehavior extends ModeBehavior

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
