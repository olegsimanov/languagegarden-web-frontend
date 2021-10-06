    'use strict'

    _ = require('underscore')
    mathPoints = require('./points')
    mathEquations = require('./equations')

    {Point} = mathPoints
    {solveQuadratic} = mathEquations


    # a*x + b*y + c = 0
    class Line
        constructor: (@a, @b, @c) ->

        copy: -> new Line(@a, @b, @c)

        toString: -> "Line(#{@a},#{@b},#{@c})"

        toArray: -> [@a, @b, @c]

        toJSON: -> a: @a, b: @b, c: @c

        equals: (l2) -> l2? and @a == l2.a and @b == l2.b and @c == l2.c

        neg: -> @copy().negateSelf()

        getYParametrizedEqParams: -> [-@a / @b, -@c / @b]

        getXParametrizedEqParams: -> [-@b / @a, -@c / @a]

        getSide: (point) -> @a * point.x + @b * point.y + @c

        getOrthogonal: -> new Point(@a, @b)

        # the tangent is assumed to be a vector which is the orthogonal vector
        # rotated 90 degrees clockwise
        getTangent: -> new Point(-@b, @a)

        project: (point) ->
            v = @getOrthogonal()
            orthogonalSqNorm = v.getSquaredNorm()
            point.subFromSelf(v.mulSelf(@getSide(point)/orthogonalSqNorm))

        getProjection: (point) -> @project(point.copy())

        # note: the negation of the line is a different thing from negating
        # a point. the negation of the line does not change the solution
        # set for given line, only changes it's orientation.
        negateSelf: ->
            [@a, @b, @c] = [-@a, -@b, -@c]
            this

        translate: (point) ->
            @c = @c - @a * point.x - @b * point.y
            this

        # CLASS METHODS

        @fromTwoPoints = (p1, p2) =>
            a = p2.y - p1.y
            b = p1.x - p2.x
            c = -(a * p1.x + b * p1.y)
            new this(a, b, c)

        @ortogonalPassingFirst = (p1, p2) =>
            l = @fromTwoPoints(p1, p2)
            [a, b] = [l.a, l.b]
            l.a = b
            l.b = -a
            l.c = -(l.a * p1.x + l.b * p1.y)
            l

        @areParallel = (ln1, ln2) => ln1.b * ln2.a - ln1.a * ln2.b == 0

        @intersectionPoint = (ln1, ln2) =>
            delta = ln1.b * ln2.a - ln1.a * ln2.b
            if delta == 0
                return NaN
            x = (ln1.c * ln2.b - ln1.b * ln2.c) / delta
            y = (ln1.a * ln2.c - ln2.a * ln1.c) / delta
            new Point(x, y)

        @functionCoeffs = (pt1, pt2) =>
            [x1, y1, x2, y2] = [pt1.x, pt1.y, pt2.x, pt2.y]
            a = (y1 - y2) / (x1 - x2)
            b = y1 - a * x1
            [a, b]

        # x = a * y + b
        @invFunctionCoeffs = (pt1, pt2) =>
            [x1, y1, x2, y2] = [pt1.x, pt1.y, pt2.x, pt2.y]
            a = (x1 - x2) / (y1 - y2)
            b = x1 - a * y1
            [a, b]

        ### Calculates points on a line at some distance from some point.
        @param distance Distance from fromPoint
        @param fromPoint A Point on the line.
        @param lineCoeffs Pair of number [a, b] defining the line y = a * x + b.
        ###
        @coordsAtDistanceOnLine = (distance, fromPoint, lineCoeffs) =>
            [a, b] = lineCoeffs
            [px, py] = fromPoint.toArray()
            sq = (x) => x * x
            xa = 1 + sq(a)
            xb = 2 * (a * (b - py) - px)
            xc = sq(px) + sq(b - py) - sq(distance)
            xx = solveQuadratic(xa, xb, xc)
            return _.map xx, (x) => [x, a * x + b]


    module.exports =
        Line: Line
        linFunctionCoeffs: Line.functionCoeffs
        invLinFunctionCoeffs: Line.invFunctionCoeffs
        coordsAtDistanceOnLine: Line.coordsAtDistanceOnLine
