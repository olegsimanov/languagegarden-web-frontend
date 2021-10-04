    'use strict'



    ###
    Solves linear equation:

        a*x + b = 0

    ###
    solveLinear = (a, b) -> -b / a


    ###
    Solves quadratic equation:

        a*x^2 + b*x + c = 0

    ###
    solveQuadratic = (a, b, c) ->
        if a == 0
            return [solveLinear(b, c)]
        delta = b * b - 4 * a * c
        if delta < 0
            []
        else if delta == 0
            [-0.5 * b / a]
        else  # delta > 0
            sqrtDelta = Math.sqrt(delta)
            [0.5 * (-b - sqrtDelta) / a, 0.5 * (-b + sqrtDelta) / a]


    ###
    Test whether linear equation system with 2 variables:

        a*x + b*y = c
        d*x + e*y = f

    is solvable.
    ###
    isLinearSystemSolvable = (a, b, c, d, e, f) -> a * e - d * b != 0


    ###
    Solves linear equation system with 2 variables:

        a*x + b*y = c
        d*x + e*y = f

    ###
    solveLinearSystem = (a, b, c, d, e, f) ->
        if d != 0 and a == 0
            # Changing the order of equations to avoid the destruction of the
            # universe (dividing by zero)
            return solveLinearSystem(d, e, f, a, b, c)
        y = (c * d - a * f) / (b * d - a * e)
        x = (c - (b * y)) / a
        [x, y]


    module.exports =
        solveLinear:            solveLinear
        solveQuadratic:         solveQuadratic
        isLinearSystemSolvable: isLinearSystemSolvable
        solveLinearSystem:      solveLinearSystem
