    'use strict'

    _ = require('underscore')
    {Line} = require('./../../math/lines')
    {Point} = require('./../../math/points')
    {ltrim, rtrim} = require('./../utils')


    getWordSplits = (view, lettersRanges) ->
        path = view.getPath()
        pathLength = path.getLength()

        elementSplits = []
        for lettersRange in lettersRanges
            [startLetterIndex, endLetterIndex] = lettersRange
            # converting letter indexes into positions on path
            if view.isTextRTL()
                endPos = view.getLetterEndPathPosition(startLetterIndex)
                startPos = view.getLetterStartPathPosition(endLetterIndex)
            else
                startPos = view.getLetterStartPathPosition(startLetterIndex)
                endPos = view.getLetterEndPathPosition(endLetterIndex)

            # get start/end of new path
            subStartPoint = path.getPointAtLength(startPos)
            subEndPoint = path.getPointAtLength(endPos)

            # convert points into [0, 1] bezier curve coordinates
            startPathPos = startPos / pathLength
            endPathPos = endPos / pathLength

            # getting control point
            subControlPoint = calculateControlPoint(
                startPathPos, endPathPos, path, subStartPoint, subEndPoint,
                startLetterIndex, endLetterIndex)

            elementSplits.push
                lettersRange: lettersRange
                pathPoints: [subStartPoint, subControlPoint, subEndPoint]

        elementSplits

    ###Finds indices to split the word into subwords by removing any space
    in the text

    @param text Text to analyze.
    @returns array Of arrays containing start, end posistions of sub-words.

    ###
    getSentenceSplitIndices = (text) ->
        results = []

        for [i, letter] in _.zip([0...text.length], text)
            if letter == ' '
                if start?
                    results.push([start, i - 1])
                    start = null
            else
                start = i if not start?
        results.push([start, i]) if start?
        results

    ###Returns the cound of blanks on the left and right of the string.###
    stringBlankCounts = (str) ->
        [
            str.length - ltrim(str).length,
            str.length - rtrim(str).length,
        ]

    ### Find a new control point for a subsection if an existing bezier
    curve from ta to tb.

    @param ta Number in [0, 1] Position of subcurve start point.
    @param tb Number in [0, 1] Position of subcurve end point.
    @param path Bezier curve.
    @param subStartPoint Subwords start point.
    @param subEndPoint Subwords end point.
    @param startLetterIndex Index of start letters in the word.
    @param endLetterIndex Index of end letters in the word.
    @return Control point for the new subcurve.
    ###
    calculateControlPoint = (ta, tb, path, subStartPoint, subEndPoint,
                             startLetterIndex, endLetterIndex) ->
        startPoint = path.getStartPoint()
        controlPoint = path.getControlPoints()[0]
        endPoint = path.getEndPoint()

        # compare letter indices to early eliminate the 1 and 2 letter case
        if endLetterIndex - startLetterIndex <= 1
            return calculateControlPointSimple(subStartPoint, subEndPoint)

        # first, find ta_start/ta_end and tb_start/tb_end
        ta_start = Point.getPointBetween(startPoint, controlPoint, ta)
        ta_end = Point.getPointBetween(controlPoint, endPoint, ta)
        tb_start = Point.getPointBetween(startPoint, controlPoint, tb)
        tb_end = Point.getPointBetween(controlPoint, endPoint, tb)

        # then find lines for ta/tb
        ta_l = Line.fromTwoPoints(ta_start, ta_end)
        tb_l = Line.fromTwoPoints(tb_start, tb_end)

        # their intersection is the control point
        if Line.areParallel(ta_l, tb_l)
            # parallel lines - use point-based case
            return calculateControlPointSimple(subStartPoint, subEndPoint)
        else
            controlPoint = Line.intersectionPoint(ta_l, tb_l)
            # apply limits similar to bend, limiting by end/start letter
            if isOutOfBounds(controlPoint, subStartPoint, subEndPoint)
                # If the point lies far to one of the sides, approximating
                # by a straight line works very well
                return calculateControlPointSimple(subStartPoint, subEndPoint)
            return controlPoint

    ###Calculates the point as the exactly between start and end.

    Used in two letter case and for extreme cases, when the control point
    resulting from a split if beyond the usual boundaries.

    ###
    calculateControlPointSimple = (subStartPoint, subEndPoint) ->
        Point.getPointBetween(subStartPoint, subEndPoint)

    ### Checks if the control points is not past start or end. ###
    isOutOfBounds = (point, startPoint, endPoint) =>
        line1 = Line.ortogonalPassingFirst(startPoint, endPoint)
        if line1.getSide(point) > 0
            return true
        line2 = Line.ortogonalPassingFirst(endPoint, startPoint)
        if line2.getSide(point) > 0
            return true
        return false

    ###
    Gets a single split position and converts it into an index array of the
    form: [[start1, end1], [start2, end2]].

    Removes spaces that would remain on both word's ends'.
    ###
    getWordSplitIndices = (text, position) ->
        # cursor position is always given as after letter, thus in
        # [1...length + 1]
        firstBlanks = stringBlankCounts(text[...position])
        secondsBlanks = stringBlankCounts(text[position...])
        indices = [
            [firstBlanks[0], position - 1 - firstBlanks[1]],
            [
                position + secondsBlanks[0],
                text.length - 1 - secondsBlanks[1]
            ]
        ]
        # filter out invalid ranges that apper when cutting off words
        # consisting of spaces only (both leading and trailing)
        _.filter(indices, (range) -> range[0] <= range[1])

    ####Gets indexes on which to split the word to trim the spaces.###
    getWordTrimIndices = (text) ->
        blanks = stringBlankCounts(text)
        [[blanks[0], text.length - blanks[1] - 1], ]

    getTrimmedWordParams = (view) ->
        getWordSplits(view, getWordTrimIndices(view.model.get('text')))


    module.exports =
        getWordSplits: getWordSplits
        getSentenceSplitIndices: getSentenceSplitIndices
        getWordSplitIndices: getWordSplitIndices
        getTrimmedWordParams: getTrimmedWordParams
