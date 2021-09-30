    'use strict'

    {ModeBehavior} = require('./base')
    LetterEditBehavior = require('./../letterbehaviors/edit').EditBehavior


    class EditBehavior extends ModeBehavior
        middleLettersClasses: [
            LetterEditBehavior,
        ]
        boundLettersClasses: [
            LetterEditBehavior,
        ]

        onModeEnter: (oldMode) =>
            super
            @model.stopTrackingChanges()
            # usually selection change should not be performed in onModeEnter
            # or in onModeLeave, because there is mode change associated with
            # it (see EditorCanvasView.onSelectChange for details) but the EDIT
            # mode is exception here (again, see EditorCanvasView.onSelectChange
            # for details)
            @parentView.deselectAll()

        onModeLeave: (newMode) =>
            insertView = @getInsertView()
            if not insertView?
                super
                return
            addOptions = {}
            if @parentView.editElementModelPosition?
                addOptions.at = @parentView.editElementModelPosition

            @parentView.wordSplitContext = @getWordSplitContext()
            insertModel = insertView.model

            insertView?.remove()
            @parentView.insertView = null

            insertModel.reduceTransform()
            text = insertModel.get('text')
            if text.length > 0
                oldMode = @parentView.mode
                @parentView.mode = newMode
                # adding the word in the edit mode would not update the
                # letter areas, therefore we add it in the 'future' mode
                @model.addElement(insertModel, addOptions)
                @parentView.mode = oldMode
            @model.startTrackingChanges()
            super

        getWordSplitContext: ->
            insertView = @getInsertView()

            position: insertView.lastCaretPos
            model: insertView.model

        getInsertView: -> @parentView.insertView


    module.exports =
        EditBehavior: EditBehavior
