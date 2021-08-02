_ = require('underscore')

{MediumType, VisibilityType} = require('./../../common/constants')
{deepCopy} = require('./../../common/utils')
{getMediumIndexByType, buildActiveActivityDiffDataHandler} = require('./base')


getActivePlantToTextDiffDataFactory = (resetP2TBox=true) ->
    buildActiveActivityDiffDataHandler (activityStartSnapshot, endSnapshot) ->
        activityStartSnapshot = deepCopy(activityStartSnapshot)
        mediumIndex = getMediumIndexByType(
            endSnapshot,
            MediumType.PLANT_TO_TEXT_NOTE,
        )
        if mediumIndex >= 0
            noteData = activityStartSnapshot.media[mediumIndex] = deepCopy(endSnapshot.media[mediumIndex])
            origNoteTextContent = deepCopy(noteData.noteTextContent)
            noteData.okNoteTextContent = origNoteTextContent
            if resetP2TBox
                noteData.noteTextContent = []
            selectedObjectids = []
            for segmentGroup in noteData.noteTextContent
                for segment in segmentGroup
                    if segment.objectId?
                        selectedObjectids.push(segment.objectId)

            for elem in activityStartSnapshot.elements
                if not (elem.objectId in selectedObjectids)
                    elem.visibilityType = VisibilityType.PLANT_TO_TEXT_FADED

        activityStartSnapshot

getActivePlantToTextDiffData = getActivePlantToTextDiffDataFactory(true)
getActivePlantToTextMemoDiffData = getActivePlantToTextDiffDataFactory(false)

module.exports =
    getActivePlantToTextDiffData: getActivePlantToTextDiffData
    getActivePlantToTextMemoDiffData: getActivePlantToTextMemoDiffData
