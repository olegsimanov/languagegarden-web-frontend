    'use strict'

    _ = require('underscore')


    simpsonRuleIntegral = (f, a, b, n=16) ->
        m = 2 * n
        dx = (b - a) / m
        sum2 = 0
        sum4 = f(a + dx)
        for i in [1...n]
            j = i * 2
            sum2 += f(a + j * dx)
            sum4 += f(a + (j + 1) * dx)

        (2 * sum2 + 4 * sum4 + f(a) + f(b)) * (1/3) * dx

    ###
    Finds x for which f(x) ~= 0
    @param f input function. it is assumed that this function has continuous
        second derivative.
    @param df input function derivative
    @param startx start function parameter
    @param epsilon optional, specifies that for output x,
        |f(x)| < epsilon must hold
    ###
    newtonFindRoot = (f, df, startx, epsilon=0.00001, numOfIterations=10) ->
        x = startx
        for i in [0...numOfIterations]
            fx = f(x)
            if _.isNaN(fx) or Math.abs(fx) < epsilon
                break
            dfx = df(x)
            x = x - fx / dfx
        x


    module.exports =
        simpsonRuleIntegral: simpsonRuleIntegral
        integral: simpsonRuleIntegral
        newtonFindRoot: newtonFindRoot
        findRoot: newtonFindRoot
