    'use strict'

    {Point} = require('./points')
    {solveLinearSystem} = require('./equations')


    ###
    Representing the linear transformation L in a following way:

        L(x,y) = (a*x + c*y, b*x + d*y)

    ###
    class LinearTransformation

        constructor: (@a, @b, @c, @d) ->
            if not @a?
                @a = @d = 1
                @b = @c = 0

        getX: (x, y) -> @a * x + @c * y

        getY: (x, y) -> @b * x + @d * y

        # for deprecated usage
        x: (x, y) -> @getX(x, y)

        y: (x, y) -> @getY(x, y)

        copy: -> new @constructor(@a, @b, @c, @d)

        getTransformedPoint: (p) -> new Point(@getX(p.x, p.y), @getY(p.x, p.y))

        _mul: (bmat, cmat) ->
            cmat.a = @a * bmat.a + @c * bmat.b
            cmat.b = @b * bmat.a + @d * bmat.b
            cmat.c = @a * bmat.c + @c * bmat.d
            cmat.d = @b * bmat.c + @d * bmat.d

        mul: (bmat) ->
            cmat = new @constructor()
            @_mul(bmat, cmat)
            cmat

        getDeterminant: ->  @a * @d - @b * @c

        toCSSTransform: -> "matrix(#{@a}, #{@b}, #{@c}, #{@d}, 0, 0)"

        # modifying operations, use with care!

        transformPoint: (p) ->
            [p.x, p.y] = [@getX(p.x, p.y), @getY(p.x, p.y)]
            p

        # CLASS METHODS

        @fromParams: (a, b, c, d) => new this(a, b, c, d, 0, 0)

        @newIdentity: => @fromParams(1, 0, 0, 1)

        @fromScaleVector: (s) => @fromParams(s.x, 0, 0, s.y)

        @fromScale: (s) => @fromParams(s, 0, 0, s)

        ###
        Returns linear transformation which fulfills following constrains:

            L(input1) = output1
            L(input2) = output2

        ###
        @fromIO: (input1, output1, input2, output2) =>
            [a, c] = solveLinearSystem(input1.x, input1.y, output1.x,
                                       input2.x, input2.y, output2.x)
            [b, d] = solveLinearSystem(input1.x, input1.y, output1.y,
                                       input2.x, input2.y, output2.y)
            @fromParams(a, b, c, d)

        ###
        Returns homothety (composition of rotation and uniform scaling)
        from one input vector and one output vector, e.g. L(input) = output.
        ###
        @homothetyFromIO: (input, output) ->
            @fromIO(input, output,
                    input.copy().rotateQuaterCCW(),
                    output.copy().rotateQuaterCCW())

        ###
        Calculate the uniform scaling/rotation transformation for input/output
        vectors. You can pass disableRotation=true and/or disableScaling=true
        to disable the rotation and/or scaling accordingly.
        ###
        @scalingRotation: (input, output, options={}) ->
            scaleFactor = output.getNorm() / input.getNorm()

            if options.disableRotation
                output = input.mul(scaleFactor)

            if options.disableScaling
                output = output.mul(1 / scaleFactor)

            @homothetyFromIO(input, output)

        @mul: (a, b) => a.mul(b)

        @inv: (a) =>
            # TODO: replace this with a.inv() when Raphael.Matrix dependency
            # is removed
            a.invert()


    ###
    Representing A(x,y) = (a*x + c*y + e, b*x + d*y + f)
    ###
    class AffineTransformation extends LinearTransformation

        constructor: (@a, @b, @c, @d, @e, @f) ->
            if not @a?
                @a = @d = 1
                @b = @c = @e = @f = 0

        getX: (x, y) -> @a * x + @c * y + @e

        getY: (x, y) -> @b * x + @d * y + @f

        copy: -> new @constructor(@a, @b, @c, @d, @e, @f)

        _mul: (bmat, cmat) ->
            cmat.a = @a * bmat.a + @c * bmat.b
            cmat.b = @b * bmat.a + @d * bmat.b
            cmat.c = @a * bmat.c + @c * bmat.d
            cmat.d = @b * bmat.c + @d * bmat.d
            cmat.e = @a * bmat.e + @c * bmat.f + @e
            cmat.f = @b * bmat.e + @d * bmat.f + @f

        toCSSTransform: -> "matrix(#{@a}, #{@b}, #{@c}, #{@d}, #{@e}, #{@f})"

        # CLASS METHODS

        @fromParams: (a, b, c, d, e, f) => new this(a, b, c, d, e, f)

        @newIdentity: => @fromParams(1, 0, 0, 1, 0, 0)

        @fromTranslationVector: (v) => @fromParams(1, 0, 0, 1, v.x, v.y)

        @fromScaleVector: (s) => @fromParams(s.x, 0, 0, s.y, 0, 0)

        @fromScale: (s) => @fromParams(s, 0, 0, s, 0, 0)

        @fromLinearTransformation: (lt) =>
            @fromParams(lt.a, lt.b, lt.c, lt.d, 0, 0)

        @fromShiftedTransform: (tf, shiftVector) =>
            @fromParams(tf.a, tf.b, tf.c, tf.d,
                        (tf.e or 0) + shiftVector.x,
                        (tf.f or 0) + shiftVector.y)

        @fromCSSTransform: (transformString) =>
            if not transformString? or transformString == 'none'
                return @newIdentity()
            prefix = 'matrix('
            if transformString.substr(0, prefix.length) != prefix
                return null
            if transformString.charAt(transformString.length - 1) != ')'
                return null

            valuesString = transformString.substring(prefix.length,
                                                     transformString.length - 1)
            values = []
            for v in valuesString.split(/, +/)
                if v != ''
                    values.push(parseFloat(v))

            @fromParams(values...)

        ###
        Calculate the scaling/rotation transformation for input/output vectors
        which are anchored at origin point. you can pass disableRotation=true
        and/or disableScaling=true to disable the rotation and/or scaling
        accordingly.
        ###
        @scalingRotation: (originPoint, inputVector, outputVector, options={}) ->
            lt = LinearTransformation.scalingRotation(inputVector, outputVector,
                                                      options)
            t1 = @fromTranslationVector(originPoint.neg())
            t2 = @fromLinearTransformation(lt)
            t3 = @fromTranslationVector(originPoint)
            t3.mul(t2.mul(t1))


    module.exports =
        LinearTransformation: LinearTransformation
        AffineTransformation: AffineTransformation
