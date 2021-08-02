    'use strict'

    _ = require('underscore')
    #TODO: remove raphael dependency
    Raphael = require('raphael')


    class Point
        constructor: (@x=0, @y=0) ->

        toJSON: -> x: @x, y: @y

        toArray: -> [@x, @y]

        toString: -> "Point(#{@x}, #{@y})"

        add: (b) -> new Point(@x + b.x, @y + b.y)

        sub: (b) -> new Point(@x - b.x, @y - b.y)

        addMul: (b, c) -> new Point(@x + c * b.x, @y + c * b.y)

        neg: -> new Point(-@x, -@y)

        mul: (c) -> new Point(c * @x, c * @y)

        vecMul: (b) -> new Point(b.x * @x, b.y * @y)

        equals: (b) -> b? and @x == b.x and @y == b.y

        getSquaredNorm: -> @x * @x + @y * @y

        getNorm: -> Math.sqrt(@getSquaredNorm())

        copy: -> new Point(@x, @y)

        getCoords: -> @toArray()

        toPointOnLinearFunction: (a, b) -> new Point(@x, a * @x + b)

        # modifying operations. use with care!

        set: (b) ->
            @x = b.x
            @y = b.y
            this

        applyMatrix: (matrix) ->
            [@x, @y] = [matrix.x(@x, @y), matrix.y(@x, @y)]
            @

        coordinates: (x=@x, y=@y) -> [@x, @y] = [x, y]

        setCoords: (x=@x, y=@y) -> [@x, @y] = [x, y]

        addToSelf: (b) ->
            @x += b.x
            @y += b.y
            this

        addMulToSelf: (b, c) ->
            @x += c * b.x
            @y += c * b.y
            this

        subFromSelf: (b) ->
            @x -= b.x
            @y -= b.y
            this

        negateSelf: ->
            @x = -@x
            @y = -@y
            this

        mulSelf: (c) ->
            @x *= c
            @y *= c
            this

        vecMulSelf: (b) ->
            @x *= b.x
            @y *= b.y
            this

        normalize: ->
            n = @getNorm()
            @x /= n
            @y /= n
            this

        rotateQuaterCCW: ->
            [@x, @y] = [@y, -@x]
            this

        # CLASS METHODS

        @fromObject = (obj) => new this(obj.x, obj.y)

        @fromArray = (arr) => new this(arr[0], arr[1])

        @fromValue = (x, y) =>
            if not y?
                if _.isArray(x) then @fromArray(x)
                else if _.isObject(x) then @fromObject(x)
            else
                new this(x, y)

        @avg = (p1, p2) => p1.add(p2).mulSelf(0.5)

        @weightedAvg = (p1, p2, t=0.5) =>
            p1.mul(1 - t).addMulToSelf(p2, t)

        @getPointBetween = @weightedAvg

        ###
        we could use the getSquaredNorm method here, but we do the calculations
        directly to avoid creating additional Point/Vector object to make it
        as fast as possible.
        ###
        @getSquaredDistance = (p1, p2) =>
            dx = p2.x - p1.x
            dy = p2.y - p1.y
            dx * dx + dy * dy

        @getDistance = (p1, p2) => Math.sqrt(@getSquaredDistance(p1, p2))

        @sqDist = @getSquaredDistance

        # gets the orthogonal to the line defined by startPoint and endPoint
        @getOrthogonal = (startPoint, endPoint) =>
            tangent = @fromObject(endPoint).subFromSelf(startPoint)
            tangent.copy().rotateQuaterCCW()

        # gets the normal to the line defined by startPoint and endPoint
        @getNormal = (startPoint, endPoint) =>
            @getOrthogonal(startPoint, endPoint).normalize()

        @scalePoints = (xscale, yscale, originX, originY, points) =>
            matrix = Raphael.matrix()
            matrix.scale(xscale, yscale, originX, originY)
            _.map points, (c) => c.applyMatrix(matrix)

        @rotatePoints = (angle, originX, originY, points) =>
            matrix = Raphael.matrix()
            matrix.rotate(angle, originX, originY)
            _.map points, (c) => c.applyMatrix(matrix)

        # TODO: move it somewhere else
        @applyMatrixToXY = (x, y, matrix) => [matrix.x(x, y), matrix.y(x, y)]

        # TODO: move functions below to matrix module

        # returns non-modifying transform function
        @getTransform = (matrix) =>
            (p) => new this(matrix.x(p.x, p.y), matrix.y(p.x, p.y))

        # returns modifying transform function
        @getTransformApplicator = (matrix) =>
            (p) ->
                [px, py] = [p.x, p.y]
                p.x = matrix.x(px, py)
                p.y = matrix.y(px, py)
                p

        # returns non-modifying vector transform function (without translations)
        @getVectorTransform = (matrix) =>
            a = matrix.a
            c = matrix.c
            b = matrix.b
            d = matrix.d
            (p) => new this(a * p.x + c * p.y,
                            b * p.x + d * p.y)

        # returns modifying vector transform function (without translations)
        @getVectorTransformApplicator = (matrix) =>
            a = matrix.a
            c = matrix.c
            b = matrix.b
            d = matrix.d
            (p) ->
                px = p.x
                py = p.y
                p.x = a * px + c * py
                p.y = b * px + d * py
                p

        @dot = (p1, p2) => p1.x * p2.x + p1.y * p2.y


    module.exports =
        Point: Point
        Vector: Point
