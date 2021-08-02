    'use strict'

    _ = require('underscore')
    {Point} = require('./../math/points')
    {Path} = require('./../math/bezier')
    {getCharRange} = require('./utils')
    {getPolygonPathString, getQuadrilateralPathString} = require('./domutils')
    {
        LinearTransformation
        AffineTransformation
    } = require('./../math/transformations')


    smallLetters =
        bigLeftTop: ['b', 'h', 'k']
        bigRightTop: ['d']
        bigTop: ['t', 'l', 'i']
        big: ['f', 'j']
        bigBottom: ['g', 'y']
        bigLeftBottom: ['p']
        bigRightBottom: ['q']

    # TODO: these values are purely experimental
    smallFactor = 0.5
    bigFactor = 0.82
    sideFactor = 0.45


    getBig = (startPoint, endPoint, orthogonal) ->
        bigOrthogonal = orthogonal.mul(bigFactor)
        a1 = startPoint.add(bigOrthogonal)
        a2 = endPoint.add(bigOrthogonal)
        a3 = endPoint.sub(bigOrthogonal)
        a4 = startPoint.sub(bigOrthogonal)
        [[a1, a2, a3, a4], getQuadrilateralPathString]

    getFull = (startPoint, endPoint, orthogonal) ->
        a1 = startPoint.add(orthogonal)
        a2 = endPoint.add(orthogonal)
        a3 = endPoint.sub(orthogonal)
        a4 = startPoint.sub(orthogonal)
        [[a1, a2, a3, a4], getQuadrilateralPathString]

    getBigTop = (startPoint, endPoint, orthogonal) ->
        smallOrthogonal = orthogonal.mul(smallFactor)
        bigOrthogonal = orthogonal.mul(bigFactor)
        a1 = startPoint.add(bigOrthogonal)
        a2 = endPoint.add(bigOrthogonal)
        a3 = endPoint.sub(smallOrthogonal)
        a4 = startPoint.sub(smallOrthogonal)
        [[a1, a2, a3, a4], getQuadrilateralPathString]

    getBigLeftTop = (startPoint, endPoint, orthogonal) ->
        smallOrthogonal = orthogonal.mul(smallFactor)
        bigOrthogonal = orthogonal.mul(bigFactor)
        interPoint = Point.weightedAvg(startPoint, endPoint, sideFactor)
        a1 = startPoint.add(bigOrthogonal)
        b1 = interPoint.add(bigOrthogonal)
        b2 = interPoint.add(smallOrthogonal)
        a2 = endPoint.add(smallOrthogonal)
        a3 = endPoint.sub(smallOrthogonal)
        a4 = startPoint.sub(smallOrthogonal)
        [[a1, b1, b2, a2, a3, a4], getPolygonPathString]

    getBigRightTop = (startPoint, endPoint, orthogonal) ->
        smallOrthogonal = orthogonal.mul(smallFactor)
        bigOrthogonal = orthogonal.mul(bigFactor)
        interPoint = Point.weightedAvg(endPoint, startPoint, sideFactor)
        a1 = startPoint.add(smallOrthogonal)
        b1 = interPoint.add(smallOrthogonal)
        b2 = interPoint.add(bigOrthogonal)
        a2 = endPoint.add(bigOrthogonal)
        a3 = endPoint.sub(smallOrthogonal)
        a4 = startPoint.sub(smallOrthogonal)
        [[a1, b1, b2, a2, a3, a4], getPolygonPathString]

    getBigBottom = (startPoint, endPoint, orthogonal) ->
        smallOrthogonal = orthogonal.mul(smallFactor)
        bigOrthogonal = orthogonal.mul(bigFactor)
        a1 = startPoint.add(smallOrthogonal)
        a2 = endPoint.add(smallOrthogonal)
        a3 = endPoint.sub(bigOrthogonal)
        a4 = startPoint.sub(bigOrthogonal)
        [[a1, a2, a3, a4], getQuadrilateralPathString]

    getBigLeftBottom = (startPoint, endPoint, orthogonal) ->
        smallOrthogonal = orthogonal.mul(smallFactor)
        bigOrthogonal = orthogonal.mul(bigFactor)
        interPoint = Point.weightedAvg(startPoint, endPoint, sideFactor)
        a1 = startPoint.add(smallOrthogonal)
        a2 = endPoint.add(smallOrthogonal)
        a3 = endPoint.sub(smallOrthogonal)
        b1 = interPoint.sub(smallOrthogonal)
        b2 = interPoint.sub(bigOrthogonal)
        a4 = startPoint.sub(bigOrthogonal)
        [[a1, a2, a3, b1, b2, a4], getPolygonPathString]

    getBigRightBottom = (startPoint, endPoint, orthogonal) ->
        smallOrthogonal = orthogonal.mul(smallFactor)
        bigOrthogonal = orthogonal.mul(bigFactor)
        interPoint = Point.weightedAvg(endPoint, startPoint, sideFactor)
        a1 = startPoint.add(smallOrthogonal)
        a2 = endPoint.add(smallOrthogonal)
        a3 = endPoint.sub(bigOrthogonal)
        b1 = interPoint.sub(bigOrthogonal)
        b2 = interPoint.sub(smallOrthogonal)
        a4 = startPoint.sub(smallOrthogonal)
        [[a1, a2, a3, b1, b2, a4], getPolygonPathString]

    getSmall = (startPoint, endPoint, orthogonal) ->
        smallOrthogonal = orthogonal.mul(smallFactor)
        a1 = startPoint.add(smallOrthogonal)
        a2 = endPoint.add(smallOrthogonal)
        a3 = endPoint.sub(smallOrthogonal)
        a4 = startPoint.sub(smallOrthogonal)
        [[a1, a2, a3, a4], getQuadrilateralPathString]

    # letter -> letter area path function mapping
    mapping = {}
    mapping[' '] = getSmall

    for l in getCharRange('A', 'Z')
        mapping[l] = getBigTop

    for l in getCharRange('0', '9')
        mapping[l] = getBigTop

    for l in getCharRange('a', 'z')
        mapping[l] = getSmall

    # specific letters override

    for l in smallLetters.bigLeftTop
        mapping[l] = getBigLeftTop

    for l in smallLetters.bigRightTop
        mapping[l] = getBigRightTop

    for l in smallLetters.bigTop
        mapping[l] = getBigTop

    for l in smallLetters.bigLeftTop
        mapping[l] = getBigLeftTop

    for l in smallLetters.bigLeftBottom
        mapping[l] = getBigLeftBottom

    for l in smallLetters.bigRightBottom
        mapping[l] = getBigRightBottom

    for l in smallLetters.bigBottom
        mapping[l] = getBigBottom

    for l in smallLetters.big
        mapping[l] = getBig

    getTransformedPath = (factor) ->
        (path, firstOrthogonal, lastOrthogonal) ->
            firstShift = firstOrthogonal.mul(factor)
            lastShift = lastOrthogonal.mul(factor)
            startToEnd = path.getEndPoint().sub(path.getStartPoint())
            transformedStartToEnd = firstShift.neg()
            .addToSelf(startToEnd)
            .addToSelf(lastShift)
            lt = LinearTransformation.homothetyFromIO(startToEnd,
                                                      transformedStartToEnd)
            at = AffineTransformation.fromShiftedTransform(lt, firstShift)
            tfApp = Point.getTransformApplicator(at)
            path.copy().applyToPoints(tfApp)


    _letterContext = (letter, startPoint, endPoint, orthogonal) ->
        # if the letter area path string function was not found, use
        # the worst case (whole area should be covered)
        fun = mapping[letter] or getFull
        # each get<lettertype> handler should return points and a callback for
        # generating the path
        [pts, pathGenerator] = fun(startPoint, endPoint, orthogonal)

    module.exports =
        getLetterAreaPathString: (args...) ->
            [pts, pathGenerator] = _letterContext(args...)
            pathGenerator(pts...)

        getLetterAreaPathPoints: (args...) -> _letterContext(args...)[0]

        getLetterAreaPathStringAndPoints: (args...) ->
            [pts, pathGenerator] = _letterContext(args...)
            {
                pathString: pathGenerator(pts...)
                pathPoints: pts
            }


        # public exports
        getBigUpperPath: getTransformedPath(bigFactor)
        getBigLowerPath: getTransformedPath(-bigFactor)
        getSmallUpperPath: getTransformedPath(smallFactor)
        getSmallLowerPath: getTransformedPath(-smallFactor)


