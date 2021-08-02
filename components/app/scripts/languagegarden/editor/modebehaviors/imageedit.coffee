    'use strict'

    {ModeBehavior} = require('./../../common/modebehaviors/base')
    LetterSelectBehavior = require('./../letterbehaviors/select').ModeSwitchAndSelectBehavior
    LetterEditBehavior = require('./../letterbehaviors/edit').EditBehavior
    MediumSelectBehavior = require('./../mediabehaviors/select').SelectBehavior
    MediumEditBehavior = require('./../mediabehaviors/edit').EditBehavior


    class ImageEditBehavior extends ModeBehavior
        mediaClasses: [
            MediumSelectBehavior,
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

        onModeEnter: (oldMode) =>
            super
            for view in @parentView.getSelectedMediaViews()
                view.updateShowControls?(true)

        onModeReset: =>
            for view in @parentView.getMediaViews()
                view.updateShowControls?(view.isSelected())

        onModeLeave: (newMode) =>
            for view in @parentView.getMediaViews()
                view.updateShowControls?(false)
            super


    class LimitedImageEditBehavior extends ImageEditBehavior
        boundLettersClasses: []
        middleLettersClasses: []


    module.exports =
        ImageEditBehavior: ImageEditBehavior
        LimitedImageEditBehavior: LimitedImageEditBehavior
