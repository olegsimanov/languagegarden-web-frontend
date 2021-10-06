    'use strict'

    _ = require('underscore')


    sum = (numbers) -> _.reduce(numbers, ((memo, num) -> memo + num), 0)

    avg = (numbers) -> sum(numbers) / numbers.length

    enumerate = (lst) -> _.zip( _.range(lst.length), lst )

    isSubset = (a, b) -> _.all(a, (x) -> x in b)

    ltrim = (text) -> text.replace(/^\s+/, '')

    rtrim = (text) -> text.replace(/\s+$/, '')

    trim = (text) -> text.replace(/^\s+|\s+$/g, '')

    startsWith = (text, prefix) -> text.substring(0, prefix.length) == prefix

    capitalize = (text) -> "#{text.charAt(0).toUpperCase()}#{text.slice(1)}"

    padLeft = (value, length, pad='0') ->
        str = '' + value
        while str.length < length
            str = pad + str
        str

    padRight = (value, length, pad) ->
        str = '' + value
        while str.length < length
            str = str + pad
        str

    base64UrlEncode = (str) ->
        b64str = btoa(str)
        b64str = b64str.replace(/\+/g,'-').replace(/\//g,'_')
        b64str = b64str.split('=')[0]
        b64str

    pathJoin = (elem, elements...) ->
        fullPath = elem
        for element in elements
            if element.length == 0
                # we omit the empty elements
                continue
            strippedElement = element
            while strippedElement[0] == '/'
                # we strip the leading '/'
                strippedElement = strippedElement.substring(1)
            if fullPath[fullPath.length - 1] != '/'
                fullPath += '/'
            fullPath += strippedElement
        fullPath

    structuralEquals = (value1, value2) ->
        if _.isArray(value1)
            if not _.isArray(value2) or value1.length != value2.length
                false
            else
                for [v1, v2] in _.zip(value1, value2)
                    if not structuralEquals(v1, v2)
                        return false
                true
        else if _.isObject(value1)
            if not _.isObject(value2)
                false
            else
                k1 = _.keys(value1)
                k2 = _.keys(value2)
                if k1.length != k2.length or _.difference(k1, k2).length != 0
                    false
                else
                    for k in k1
                        v1 = value1[k]
                        v2 = value2[k]
                        if not structuralEquals(v1, v2)
                            return false
                    true
        else
            value1 == value2

    deepCopy = (value) ->
        if _.isArray(value)
            (deepCopy(elem) for elem in value)
        else if _.isObject(value)
            result = {}
            for own k, v of value
                result[k] = deepCopy(v)
            result
        else value


    generateRanges = (positions, len) ->
        positions = _.uniq(_.sortBy(positions, _.identity), true)
        positions = _.filter(positions, (x) => 0 < x and x < len)
        startPositions = [0].concat(positions)
        endPositions = positions.concat([len])

        _.zip(startPositions, endPositions)

    getCharRange = (first, last) -> (String.fromCharCode(code) for code in [first.charCodeAt(0)..last.charCodeAt(0)])

    rgbToHex = (r, g, b) =>
        toHexString = (a) ->
            a = a.toString(16)
            if a.length == 1 then "0" + a else a
        "#{toHexString(r)}{toHexString(g)}{toHexString(b)}"

    hexToRgb = (hex) =>
        result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        if result
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        else
            null

    parseColor = (color) ->
        #TODO: full css support
        #TODO: move it somewhere else

        # hex color
        if (match = /^#([0-9A-Fa-f]{1,2})([0-9A-Fa-f]{1,2})([0-9A-Fa-f]{1,2})$/.exec(color))?
            r = parseInt(match[1], 16)
            g = parseInt(match[2], 16)
            b = parseInt(match[3], 16)
            a = null

        # rgba color
        if (match = /^rgba\(([0-9]+),([0-9]+),([0-9]+),([0-9]+(\.[0-9]+)?)\)$/.exec(color))?
            r = parseInt(match[1], 10)
            g = parseInt(match[2], 10)
            b = parseInt(match[3], 10)
            a = parseFloat(match[4])

        r: r
        g: g
        b: b
        a: a

    isDarkColor = (hexOrR, g, b) =>
        if g? and b?
            r = hexOrR
        else
            [r, g, b] = _.values(hexToRgb(hexOrR))
        127.5 < _.reduce([r, g, b], ((m, n) -> m + n), 0)

    getValue = (val) => if _.isFunction(val) then val() else val

    slugify = (text) =>
        text.toLowerCase()
            .replace(/[^\w ]+/g,'')
            .replace(/\s+/g,'-')

    toIndex = (name) -> parseInt(name, 10)

    insertIntoArray = (arr, index, newValue) ->
        left = arr.splice(0, index)
        arr.unshift(newValue)
        arr.unshift(left...)
        arr

    replaceInArray = (arr, index, newValue) ->
        left = arr.splice(0, index)
        arr.shift()
        arr.unshift(newValue)
        arr.unshift(left...)
        arr

    deleteFromArray = (arr, index) ->
        left = arr.splice(0, index)
        arr.shift()
        arr.unshift(left...)
        arr


    isASCII = (value) ->
        for i in [0...value.length]
            if value.charCodeAt(i) >= 128
                return false
        true

    unicodeSeqPrefixes =
        0: '\\u0000'
        1: '\\u000'
        2: '\\u00'
        3: '\\u0'
        4: '\\u'

    replaceWithUnicodeSequences = (jsonString) ->
        acc = []
        for c in jsonString
            code = c.charCodeAt(0)
            if code >= 128
                codeHex = code.toString(16)
                codeString = unicodeSeqPrefixes[codeHex.length] + codeHex
                acc.push(codeString)
            else
                acc.push(c)
        acc.join('')

    stringifyToASCIIJSON = (value, replacer, space) ->
        jsonString = JSON.stringify(value, replacer, space)
        if isASCII(jsonString)
            jsonString
        else
            replaceWithUnicodeSequences(jsonString)

    nonalphaRegExp = /[ \xa0\n\t?!,.:;]/

    chopIntoWords = (text) ->
        splits = []
        while true
            m = nonalphaRegExp.exec(text)
            if not m?
                break
            elemText = text.substr(0, m.index)
            if elemText.length > 0
                splits.push(elemText)
            sepText = m[0]
            if sepText == ' '
                sepText = '\xa0'
            splits.push(sepText)

            text = text.substr(m.index + sepText.length)
        if text.length > 0
            splits.push(text)
        splits

    isWord = (text) ->
         text != '' and not nonalphaRegExp.exec(text)?

    isWordOrEmpty = (text) -> not nonalphaRegExp.exec(text)?

    getAttrsOpts = (key, val, options) =>
        if typeof key == 'object'
            attrs = _.clone(key) or {}
            options = val
        else
            attrs = {}
            attrs[key] = val
        [attrs, options]


    fromHex = (hex) -> parseInt(hex, 16)

    arabicRanges = [
        [fromHex('0600'), fromHex('06FF')]
        [fromHex('0750'), fromHex('077F')]
        [fromHex('08A0'), fromHex('08FF')]
        [fromHex('FB50'), fromHex('FDFF')]
        [fromHex('FE70'), fromHex('FEFF')]
        [fromHex('10E60'), fromHex('10E7F')]
        [fromHex('1EE00'), fromHex('1EEFF')]
    ]

    isArabicLetter = (letter) ->
        letterCode = letter.charCodeAt(0)
        for [first, last] in arabicRanges
            if first <= letterCode <= last
                return true
        return false


    nonJoinableFirstLetters = [
        '\u0627',
        '\u0623',  # '\u0627' with hamza
        '\u062f',
        '\u0630',  # '\u062f' with hamza
        '\u0631',
        '\u0632',  # '\u0631' with hamza
        '\u0648',
        '\u0624',  # '\u0648' with hamza

        '\u0621', # hamza
    ]


    nonJoinableSecondLetters = [
        '\u0621', # hamza
    ]


    areLettersJoinable = (firstLetter, secondLetter) ->
        if not firstLetter? or not secondLetter?
            return false
        if firstLetter in nonJoinableFirstLetters
            return false
        if secondLetter in nonJoinableSecondLetters
            return false
        return true


    wrapLetterWithZWJ = (letter, options) ->
        if isArabicLetter(letter)
            wrappedLetter = letter
            if areLettersJoinable(options?.previousLetter, letter)
                wrappedLetter = '\u200D' + wrappedLetter
            if areLettersJoinable(letter, options?.nextLetter)
                wrappedLetter =  wrappedLetter + '\u200D'
            wrappedLetter
        else
            letter


    module.exports =

        sum: sum
        avg: avg
        getCharRange: getCharRange
        isSubset: isSubset
        ltrim: ltrim
        rtrim: rtrim
        trim: trim
        startsWith: startsWith
        capitalize: capitalize
        pad: padLeft
        padLeft: padLeft
        padRight: padRight
        isArabicLetter: isArabicLetter
        areLettersJoinable: areLettersJoinable
        wrapLetterWithZWJ: wrapLetterWithZWJ
        base64UrlEncode: base64UrlEncode
        pathJoin: pathJoin
        structuralEquals: structuralEquals
        deepCopy: deepCopy
        generateRanges: generateRanges
        enumerate: enumerate
        rgbToHex: rgbToHex
        hexToRgb: hexToRgb
        parseColor: parseColor
        isDarkColor: isDarkColor

        getValue: getValue
        slugify: slugify

        toIndex: toIndex
        insertIntoArray: insertIntoArray
        replaceInArray: replaceInArray
        deleteFromArray: deleteFromArray

        stringifyToASCIIJSON: stringifyToASCIIJSON
        isASCII: isASCII

        isWord: isWord
        isWordOrEmpty: isWordOrEmpty
        chopIntoWords: chopIntoWords
        getAttrsOpts: getAttrsOpts
