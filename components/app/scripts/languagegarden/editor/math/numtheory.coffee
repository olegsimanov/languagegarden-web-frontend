    'use strict'



    gcd = (a, b) ->
        a = Math.abs(a)
        b = Math.abs(b)
        if b > a
            [b,a] = [a,b]
        while b > 0
            c = a % b
            a = b
            b = c
        a


    lcm = (a, b) -> a * b / gcd(a, b)


    module.exports =
        gcd: gcd
        lcm: lcm
