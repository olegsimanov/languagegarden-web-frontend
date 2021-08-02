    'use strict'

    _ = require('underscore')
    {Point} = require('./points')
    {BBox} = require('./bboxes')
    {invLinFunctionCoeffs} = require('./lines')
    {solveLinear, solveLinearSystem} = require('./equations')
    {integral, findRoot} = require('./numeric')


    ###
    De Casteljau algorithm

    http://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm

    WARNING! for performance reasons this returns the same Point object
    (but with changed coordinates). Be sure to copy it if necessary.
    ###
    deCasteljau = (points) ->
        n = points.length - 1
        pointsLen = points.length
        pointsBuffer = (p.copy() for p in points)
        (t) ->
            _t = 1 - t
            for i in [0...pointsLen]
                pointsBuffer[i].set(points[i])
            for i in [0...n]
                m = n - i
                for k in [0...m]
                    pointsBuffer[k].mulSelf(_t).addMulToSelf(pointsBuffer[k + 1], t)
            pointsBuffer[0]

    calculateDiffPoints = (points) ->
        (points[k + 1].sub(points[k]) for k in [0...(points.length - 1)])


    class Path
        constructor: (@startPoint, @endPoint, @controlPoints=[]) ->
            @invalidateCache()

        ###
        This method should be called each time the
        this.startPoint, this.endPoint, this.controlPoints have been changed.
        ###
        setupCache: ->
            @_cacheSetUp = true
            @_lengths = {}
            points = @getPoints()
            diffPoints = calculateDiffPoints(points)
            diff2Points = calculateDiffPoints(diffPoints)
            @_degree = @controlPoints.length + 1
            @_integralN = if @_degree <= 2 then 4 else 12
            @_deCasteljau = deCasteljau(@getPoints())
            @_diffDeCasteljau = deCasteljau(diffPoints)
            @_diff2DeCasteljau = deCasteljau(diff2Points)

        invalidateCache: ->
            @_cacheSetUp = false

        ensureCache: ->
            if not @_cacheSetUp
                @setupCache()

        getStartPoint: -> @startPoint

        getEndPoint: -> @endPoint

        getControlPoints: -> @controlPoints

        toJSON: ->
            startPoint: @startPoint.toJSON()
            endPoint: @endPoint.toJSON()
            controlPoints: (cp.toJSON() for cp in @controlPoints)

        equals: (b) ->
            if not b? or not b.controlPoints?
                return false
            if not @startPoint.equals(b.startPoint)
                return false
            if not @endPoint.equals(b.endPoint)
                return false
            if @controlPoints.length != b.controlPoints.length
                return false
            for i in [0...@controlPoints.length]
                if not @controlPoints[i].equals(b.controlPoints[i])
                    return false
            return true

        ###
        Returns all points (start, control, end) as flat array of points
        ###
        getPoints: -> [@startPoint].concat(@controlPoints).concat([@endPoint])

        getDegree: -> @_degree

        ###
        Returns the point on Bezier curve at given time parameter within real
        segment [0, 1]
        ###
        getPointAt: (t) ->
            @ensureCache()
            @_deCasteljau(t).copy()

        ###
        Returns the derivative (tangent) at given time parameter within real
        segment [0, 1]
        ###
        getDerivativeAt: (t) ->
            @ensureCache()
            @_diffDeCasteljau(t).mul(@_degree)

        _getDerivativeLength: (t) ->
            @_diffDeCasteljau(t).getNorm() * @_degree

        _getXDerivativeAt: (t) ->
            @_diffDeCasteljau(t).x * @_degree

        _getYDerivativeAt: (t) ->
            @_diffDeCasteljau(t).y * @_degree

        _getXSecondDerivativeAt: (t) ->
            @_diff2DeCasteljau(t).x * @_degree * (@_degree - 1)

        _getYSecondDerivativeAt: (t) ->
            @_diff2DeCasteljau(t).y * @_degree * (@_degree - 1)

        getTangentAt: (t) -> @getDerivativeAt(t)

        getOrthogonalAt: (t) ->
            @getDerivativeAt(t).rotateQuaterCCW()

        ###
        Calculates the time parameters within [0,1] segment where the extremum
        exists (e.g. the derivative of either x coordinate or y coordinate is
        equal to 0).
        ###
        getExtremaTimes: ->
            @ensureCache()
            if @_degree < 2
                return []
            # TODO: special case for degree 2, which is faster than the
            # generic one below
            times = []
            for startT in [0, 1]
                f = (t) => @_getXDerivativeAt(t)
                df = (t) => @_getXSecondDerivativeAt(t)
                resultT = findRoot(f, df, startT)
                if 0 < resultT < 1
                    times.push(resultT)
            for startT in [0, 1]
                f = (t) => @_getYDerivativeAt(t)
                df = (t) => @_getYSecondDerivativeAt(t)
                resultT = findRoot(f, df, startT)
                if 0 < resultT < 1
                    times.push(resultT)

            _.uniq(times)

        ###
        Returns extrema points on Bezier curve.
        ###
        getExtremaPoints: ->
            @getPointAt(t) for t in @getExtremaTimes()

        getBBox: ->
            BBox.fromPointList([@startPoint, @endPoint].concat(@getExtremaPoints()))

        ###
        Calculates the length of the curve on from point at t=0 to
        point at t=endT. See:

        http://en.wikipedia.org/wiki/Arc_length
        http://en.wikipedia.org/wiki/Differential_geometry_of_curves#Length_and_natural_parametrization

        for details.
        ###
        _getLength: (endT) ->
            f = (t) => @_getDerivativeLength(t)
            integral(f, 0, endT, @_integralN)

        ###
        Returns the length of the curve on from point at t=0 to
        point at t=endT. By default, it assumes endT=1 so the length of
        whole curve is returned.
        ###
        getLength: (endT=1) ->
            @ensureCache()
            if not @_lengths[endT]?
                @_lengths[endT] = @_getLength(endT)
            @_lengths[endT]

        ###
        Finds the time parameter T for which getLength(T) ~= length.
        For details, please read:

        http://www.geometrictools.com/Documentation/MovingAlongCurveSpecifiedSpeed.pdf
        ###
        getTimeByLength: (length) ->
            startT = length / @getLength()
            # we actually search for root of function
            # f(t) = getLength(t) - length
            f = (t) => @getLength(t) - length
            df = (t) => @_getDerivativeLength(t)
            findRoot(f, df, startT, 0.1)

        ###
        NATURAL PARAMETRIZATION METHODS
        ###

        getPointAtLength: (length) ->
            @getPointAt(@getTimeByLength(length))

        getPointsAtLengths: (lengths) ->
            @getPointAtLength(l) for l in lengths

        getOrthogonalAtLength: (length) ->
            @getOrthogonalAt(@getTimeByLength(length))

        getOrthogonalsAtLengths: (lengths) ->
            @getOrthogonalAtLength(length) for length in lengths

        toString: ->
            pointsStr = @getPoints().join(', ')
            "Path(#{pointsStr})"

        copy: -> new Path(@startPoint.copy(), @endPoint.copy(),
                          (cp.copy() for cp in @controlPoints))

        # modifying operations, use with care!

        setData: (startPoint, endPoint, controlPoints=[]) ->
            if (_.isEqual(startPoint, @startPoint) and
                    _.isEqual(endPoint, @endPoint) and
                    _.isEqual(controlPoints, @controlPoints))
                return
            @startPoint = startPoint.copy()
            @endPoint = endPoint.copy()
            @controlPoints = (cp.copy() for cp in controlPoints)
            @invalidateCache()
            this

        setFromPath: (path) ->
            @setData(path.startPoint, path.endPoint, path.controlPoints)

        applyToPoints: (applicator) ->
            applicator(@startPoint)
            applicator(@endPoint)
            for cp in @controlPoints
                applicator(cp)
            @invalidateCache()
            this

    ###
    the following function calculates the control point c for quadratic bezier
    curve with start point s, end point e, and intersecting point p. this is
    equivalent to solving following system of equations:

    t^2 * s.x  +  2*t*(1 - t) * c.x  +  (1 - t)^2 * e.x - p.x = 0       (1)
    t^2 * s.y  +  2*t*(1 - t) * c.y  +  (1 - t)^2 * e.y - p.y = 0       (2)

    because there are 3 unknown variables (c.x, c.y, t) following assumption
    (named later assumption (3)) is added: the control point should lie on
    a line which is defined by two points: the average of s and e
    and the point p itself.
    ###
    calculateQuadraticCtrlPoint = (s, e, p) ->
        avg = Point.avg(e, s)
        eqPointsDiff = avg.sub(p)
        if eqPointsDiff.y != 0
            ###
            c.x can be expressed as: c.x = a * c.y + b using the assumption (3).
            a and b are calculated below.
            ###
            [a, b] = invLinFunctionCoeffs(avg, p)

            ###
            we multiply equation (2) by a and add 2*t*(1-t) (b - b) to left
            hand side of it. Now we subtract the equation (1) where c.x is
            replaced by (a * c.y + b), which removes the c.x and c.y terms,
            and thus we can calculate the unknown t variable.
            ###

            #coeffA = a * s.y + a * e.y - s.x - e.x  + 2 * b
            # TODO: this reduces to linear equation - check it
            coeffA = 0
            coeffB = (-2 * a * e.y) + (2 * e.x) - 2 * b
            coeffC = a * e.y - a * p.y - e.x + p.x

            if coeffB == 0
                avg
            else
                t = solveLinear(coeffB, coeffC)
                _t = 1 - t
                c = new Point()

                # we use equation (2) to find c.y
                c.y = - (t * t * s.y + _t * _t * e.y - p.y) / (2 * t * _t)
                # and c.x = a * c.y + b to find c.x
                c.x = a * c.y + b
                c
        else if eqPointsDiff.x != 0 # eqPointsDiff.y == 0
            c = new Point()
            ###
            c.y can be expressed as: c.y = a * c.x + b using the assumption (3).
            a and b are calculated below. a = 0 in this case, so c.y can be
            calculated directly.
            ###
            c.y = avg.y
            b = c.y

            coeffB = + e.y - s.y
            coeffC = - e.y + p.y

            if coeffB == 0
                avg
            else
                t = solveLinear(coeffB, coeffC)
                _t = 1 - t
                # we use equation (1) to find c.x
                c.x = - (t * t * s.x + _t * _t * e.x - p.x) / (2 * t * _t)
                c
        else # p == avg
            avg


    ### Finds control points for cubic bezier curve with given start, end and two
    arbitrary points on the curve.

    Source: http://stackoverflow.com/questions/2315432

    ###
    calcuateCubicCtrlPoints = (start, end, l1, l2) =>

        [x0, y0] = start
        [x3, y3] = end
        [x4, y4] = l1
        [x5, y5] = l2

        c1 = Math.sqrt((x4 - x0) * (x4 - x0) + (y4 - y0) * (y4 - y0))
        c2 = Math.sqrt((x5 - x4) * (x5 - x4) + (y5 - y4) * (y5 - y4))
        c3 = Math.sqrt((x3 - x5) * (x3 - x5) + (y4 - y5) * (y4 - y5))

        t1 = c1 / (c1 + c2 + c3)
        t2 = (c1 + c2) / (c1 + c2 + c3)

        b0 = (t) => Math.pow(1 - t, 3)
        b1 = (t) => t * (1 - t) * (1 - t) * 3
        b2 = (t) => (1 - t) * t * t * 3
        b3 = (t) => Math.pow(t, 3)

        [x1, x2] = solveLinearSystem(b1(t1), b2(t1), x4 - (x0 * b0(t1)) - (x3 * b3(t1)), b1(t2), b2(t2), x5 - (x0 * b0(t2)) - (x3 * b3(t2)))
        [y1, y2] = solveLinearSystem(b1(t1), b2(t1), y4 - (y0 * b0(t1)) - (y3 * b3(t1)), b1(t2), b2(t2), y5 - (y0 * b0(t2)) - (y3 * b3(t2)))

        [[x1, y1], [x2, y2]]


    module.exports =
        Path: Path
        calculateQuadraticCtrlPoint: calculateQuadraticCtrlPoint
        calcuateCubicCtrlPoints: calcuateCubicCtrlPoints
