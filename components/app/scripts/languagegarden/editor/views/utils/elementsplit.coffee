    'use strict'

    _               = require('underscore')

    {ltrim, rtrim}  = require('./../../utils')

    {Line}          = require('./../../math/lines')
    {Point}         = require('./../../math/points')


    stringBlankCounts = (str) ->
        [
            str.length - ltrim(str).length,
            str.length - rtrim(str).length,
        ]

    calculateControlPoint = (ta, tb, path, subStartPoint, subEndPoint, startLetterIndex, endLetterIndex) ->
        startPoint = path.getStartPoint()
        controlPoint = path.getControlPoints()[0]
        endPoint = path.getEndPoint()

        if endLetterIndex - startLetterIndex <= 1
            return calculateControlPointSimple(subStartPoint, subEndPoint)

        ta_start = Point.getPointBetween(startPoint, controlPoint, ta)
        ta_end = Point.getPointBetween(controlPoint, endPoint, ta)
        tb_start = Point.getPointBetween(startPoint, controlPoint, tb)
        tb_end = Point.getPointBetween(controlPoint, endPoint, tb)

        ta_l = Line.fromTwoPoints(ta_start, ta_end)
        tb_l = Line.fromTwoPoints(tb_start, tb_end)

        if Line.areParallel(ta_l, tb_l)
            return calculateControlPointSimple(subStartPoint, subEndPoint)
        else
            controlPoint = Line.intersectionPoint(ta_l, tb_l)
            if isOutOfBounds(controlPoint, subStartPoint, subEndPoint)
                return calculateControlPointSimple(subStartPoint, subEndPoint)
            return controlPoint

    calculateControlPointSimple = (subStartPoint, subEndPoint) -> Point.getPointBetween(subStartPoint, subEndPoint)

    isOutOfBounds = (point, startPoint, endPoint) =>
        line1 = Line.ortogonalPassingFirst(startPoint, endPoint)
        if line1.getSide(point) > 0
            return true
        line2 = Line.ortogonalPassingFirst(endPoint, startPoint)
        if line2.getSide(point) > 0
            return true
        return false

    getWordTrimIndices = (text) ->
        blanks = stringBlankCounts(text)
        [[blanks[0], text.length - blanks[1] - 1], ]

    getWordSplitIndices = (text, position) ->
        firstBlanks = stringBlankCounts(text[...position])
        secondsBlanks = stringBlankCounts(text[position...])
        indices = [
            [firstBlanks[0], position - 1 - firstBlanks[1]],
            [
                position + secondsBlanks[0],
                text.length - 1 - secondsBlanks[1]
            ]
        ]
        _.filter(indices, (range) -> range[0] <= range[1])

    getTrimmedWordParams = (view) ->
        getWordSplits(view, getWordTrimIndices(view.model.get('text')))

    getWordSplits = (view, lettersRanges) ->

        path = view.getPath()
        pathLength = path.getLength()

        elementSplits = []
        for lettersRange in lettersRanges
            [startLetterIndex, endLetterIndex] = lettersRange
            if view.isTextRTL()
                endPos = view.getLetterEndPathPosition(startLetterIndex)
                startPos = view.getLetterStartPathPosition(endLetterIndex)
            else
                startPos = view.getLetterStartPathPosition(startLetterIndex)
                endPos = view.getLetterEndPathPosition(endLetterIndex)

            subStartPoint = path.getPointAtLength(startPos)
            subEndPoint = path.getPointAtLength(endPos)

            startPathPos = startPos / pathLength
            endPathPos = endPos / pathLength

            subControlPoint = calculateControlPoint(
                startPathPos, endPathPos, path, subStartPoint, subEndPoint,
                startLetterIndex, endLetterIndex)

            elementSplits.push
                lettersRange: lettersRange
                pathPoints: [subStartPoint, subControlPoint, subEndPoint]

        elementSplits

    module.exports =
        getWordSplits:              getWordSplits
        getWordSplitIndices:        getWordSplitIndices
        getTrimmedWordParams:       getTrimmedWordParams
