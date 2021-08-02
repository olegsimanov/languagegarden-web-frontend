    'use strict'

    __raphael = require('raphael')
    _ = require('underscore')
    {UnitState} = require('./../common/models/plants')
    {Point} = require('./../math/points')
    {PlacementType, MediumType} = require('./../common/constants')
    {rewindUsingDiffs, getDiff} = require('./../common/diffs/utils')
    {enumerate, deepCopy} = require('./../common/utils')
    {BBox} = require('./../math/bboxes')


    getBoxFromElements = (elements) ->
        points = []
        for elem in elements
            fontSize = elem.get('fontSize')
            shift1 = Point.fromValue(0, fontSize)
            shift2 = Point.fromValue(0, -fontSize)
            for p in elem.getPoints()
                points.push(p.add(shift1), p.add(shift2))
        BBox.fromPointList(points)

    ###
    TODO: this is too long, split it
    ###
    getMediaDiffData = (options = {}) ->
        imageProportion = 0.5
        elemProportion = 0.5

        typePred = (mediumType) ->
            (opt) -> opt.type == mediumType

        dataSnapshot = options.dataSnapshot
        canvasWidth = dataSnapshot.canvasWidth
        canvasHeight = dataSnapshot.canvasHeight

        originalDiffs = options.originalDiffs
        startSnapshot = options.startSnapshot
        snapshot = deepCopy(startSnapshot)
        rewindUsingDiffs(snapshot, originalDiffs, 0, originalDiffs.length)
        markedObjectIds = snapshot.markedObjectIds
        newMediaOptions = snapshot.media[startSnapshot.media.length..]
        newSoundsOptions = _.filter(newMediaOptions,
                                    typePred(MediumType.SOUND))
        newImagesOptions = _.filter(newMediaOptions,
                                    typePred(MediumType.IMAGE))
        textToPlantsOptions = _.filter(snapshot.media,
                                       typePred(MediumType.TEXT_TO_PLANT))
        soundOptions = deepCopy(newSoundsOptions[0])
        imageOptions = deepCopy(newImagesOptions[0])

        textToPlantOptions = deepCopy(textToPlantsOptions[0])
        textToPlantIndex = null
        for i in [0...snapshot.media.length]
            if snapshot.media[i].objectId == textToPlantOptions.objectId
                textToPlantIndex = i

        modelCopy = new UnitState()
        modelCopy.set(startSnapshot)

        elemWidth = elemProportion * canvasWidth
        elemHeight = canvasHeight
        imageWidth = imageProportion * canvasWidth
        imageHeight = canvasHeight
        oldSnapshot = modelCopy.toNormalizedJSON()

        textToPlantModel = modelCopy.media.at(textToPlantIndex)
        textToPlantModel.set(textToPlantOptions)

        newSnapshot = modelCopy.toNormalizedJSON()
        textToPlantDiff = getDiff(oldSnapshot, newSnapshot)
        oldSnapshot = newSnapshot

        for elem in modelCopy.elements.models[..]
            if not (elem.get('objectId') in markedObjectIds)
                modelCopy.elements.remove(elem)

        newSnapshot = modelCopy.toNormalizedJSON()
        removeElementsDiff = getDiff(oldSnapshot, newSnapshot)
        oldSnapshot = newSnapshot

        bbox = getBoxFromElements(modelCopy.elements.models)
        oldCenter = bbox.getCenterPoint()
        newCenter = Point.fromValue(canvasWidth - elemWidth * 0.5,
                                    canvasHeight * 0.5)
        moveVector = newCenter.sub(oldCenter)

        elemsMatrix = Raphael.matrix()

        scaleFactorX = elemWidth / bbox.getWidth()
        scaleFactorY = elemHeight / bbox.getHeight()

        if scaleFactorX < 1.0 or scaleFactorY < 1.0
            scaleFactor = _.min([scaleFactorX, scaleFactorY])
            elemsMatrix.scale(scaleFactor, scaleFactor,
                              oldCenter.x, oldCenter.y)
            elemsMatrix.translate(moveVector.x / scaleFactor,
                                  moveVector.y / scaleFactor)
        else
            scaleFactor = 1.0
            elemsMatrix.translate(moveVector.x, moveVector.y)

        transform = Point.getTransform(elemsMatrix)

        for elem in modelCopy.elements.models
            elem.set('fontSize', scaleFactor * elem.get('fontSize'))
            elem.set('startPoint', transform(elem.get('startPoint')))
            elem.set('endPoint', transform(elem.get('endPoint')))
            ctrlPoints = elem.get('controlPoints')
            elem.set('controlPoints', (transform(cp) for cp in ctrlPoints))

        newSnapshot = modelCopy.toNormalizedJSON()
        moveElementsDiff = getDiff(oldSnapshot, newSnapshot)
        oldSnapshot = newSnapshot

        insertSoundDiff = []
        insertImageDiff = []
        scaleImageDiff = []

        if soundOptions?
            modelCopy.media.add(soundOptions)

            newSnapshot = modelCopy.toNormalizedJSON()
            insertSoundDiff = getDiff(oldSnapshot, newSnapshot)
            oldSnapshot = newSnapshot

        if imageOptions?
            imageOptions.scaleVector = [0.001, 0.001]
            imageOptions.maxDeviationVector = [imageWidth * 0.5,
                                               canvasHeight * 0.5]
            imageOptions.centerPoint = [imageWidth * 0.5,
                                        canvasHeight * 0.5]
            imageOptions.placementType = PlacementType.CANVAS
            modelCopy.media.add(imageOptions)
            imageModel = modelCopy.media.at(modelCopy.media.length - 1)

            newSnapshot = modelCopy.toNormalizedJSON()
            insertImageDiff = getDiff(oldSnapshot, newSnapshot)
            oldSnapshot = newSnapshot

            imageModel.set('scaleVector', [1.0, 1.0])

            newSnapshot = modelCopy.toNormalizedJSON()
            scaleImageDiff = getDiff(oldSnapshot, newSnapshot)
            oldSnapshot = newSnapshot

        if imageOptions?
            diffs = [
                textToPlantDiff.concat(removeElementsDiff)
                .concat(insertSoundDiff),
                moveElementsDiff.concat(insertImageDiff),
                scaleImageDiff,
            ]
        else
            diffs = [
                textToPlantDiff.concat(removeElementsDiff)
                .concat(insertSoundDiff),
            ]

        diffs: diffs


    module.exports =
        getMediaDiffData: getMediaDiffData
