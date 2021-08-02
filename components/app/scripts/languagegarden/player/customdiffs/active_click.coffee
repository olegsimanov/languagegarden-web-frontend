_ = require('underscore')

{MediumType} = require('./../../common/constants')
{deepCopy} = require('./../../common/utils')
{getMediumIndexByType, buildActiveActivityDiffDataHandler} = require('./base')


getActiveClickDiffData = buildActiveActivityDiffDataHandler (activityStartSnapshot, endSnapshot) ->
    activityStartSnapshot = deepCopy(activityStartSnapshot)
    mediumIndex = getMediumIndexByType(
        endSnapshot,
        MediumType.INSTRUCTIONS_NOTE,
    )
    if mediumIndex >= 0
        activityStartSnapshot.media[mediumIndex] = deepCopy(endSnapshot.media[mediumIndex])
        for elem in activityStartSnapshot.elements
            elem.marked = false

    activityStartSnapshot


module.exports =
    getActiveClickDiffData: getActiveClickDiffData
