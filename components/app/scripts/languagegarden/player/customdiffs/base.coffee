_ = require('underscore')

{deepCopy, generateRanges} = require('./../../common/utils')
{getDiff, rewindUsingDiffs} = require('./../../common/diffs/utils')
{reduceDiff} = require('./../../common/diffs/reductions')
{findAutoKeyFramePositions} = require('./../../common/autokeyframes')


getMediumIndexByType = (snapshot, type) ->
    for i in [0...snapshot.media.length]
        m = snapshot.media[i]
        if m.type == type
            return i

    return -1


getMediumSnapshotByType = (snapshot, type) ->
    index = getMediumIndexByType(snapshot, type)
    if index >= 0
        snapshot.media[index]
    else
        null


getSnapshots = (options) ->
    originalDiffs = options.originalDiffs
    startSnapshot = options.startSnapshot
    stationPositions = options.stationPositions

    endSnapshot = deepCopy(startSnapshot)
    finalStartSnapshot = deepCopy(startSnapshot)
    if stationPositions.length > 0
        finalStartPosition = stationPositions[0]
    else
        finalStartPosition = 0

    rewindUsingDiffs(endSnapshot, originalDiffs, 0, originalDiffs.length)
    rewindUsingDiffs(finalStartSnapshot, originalDiffs, 0, finalStartPosition)

    activityStartSnapshot: finalStartSnapshot
    activityStartPosition: finalStartPosition
    endSnapshot: endSnapshot


getDefaultDiffData = (options) ->
    originalDiffs = options.originalDiffs
    origStationPositions = options.stationPositions
    keyFramePositions = options.keyFramePositions
    diffsList = []
    stationPositions = []
    i = 0

    for [start, end] in generateRanges(keyFramePositions, originalDiffs.length)
        rangeDiffs = originalDiffs[start...end]
        subPositions = findAutoKeyFramePositions(rangeDiffs)
        subDiffs = []
        for [subStart, subEnd] in generateRanges(subPositions, rangeDiffs.length)
            subRangeDiffs = rangeDiffs[subStart...subEnd]
            keyframeTransitionDiff = _.flatten(subRangeDiffs)
            subDiffs.push(reduceDiff(keyframeTransitionDiff))

        diffsList.push(subDiffs)
        if end in origStationPositions
            pos = i + 1
            stationPositions.push(pos)
        i += 1

    diffsList: diffsList
    stationPositions: stationPositions


buildActiveActivityDiffDataHandler = (activeActivityTransfrom) ->
    (options) ->
        {startSnapshot, originalDiffs} = options
        {
            activityStartSnapshot
            activityStartPosition
            endSnapshot
        } = getSnapshots(options)

        activeActivityStartSnapshot = activeActivityTransfrom(
            activityStartSnapshot, endSnapshot,
        )

        opts = _.extend {}, options,
            originalDiffs: originalDiffs[0...activityStartPosition]

        # generate additional diff for active activity initialization
        diff = getDiff(activityStartSnapshot, activeActivityStartSnapshot)

        diffData = getDefaultDiffData(opts)
        if diffData.diffsList?.length > 0 and diff.length > 0
            diffData.diffsList[0].push(diff)

        data =
            startSnapshot: startSnapshot
            activityStartSnapshot: activeActivityStartSnapshot
            endSnapshot: endSnapshot

        _.extend(data, diffData)

        data


module.exports =
    getMediumIndexByType: getMediumIndexByType
    getMediumSnapshotByType: getMediumSnapshotByType
    getSnapshots: getSnapshots
    getDefaultDiffData: getDefaultDiffData
    buildActiveActivityDiffDataHandler: buildActiveActivityDiffDataHandler
