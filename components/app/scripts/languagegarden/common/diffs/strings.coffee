    'use strict'


    stringDiff = (str1, str2) ->

        if str1 == str2
            return [0, 0, '']

        if str1 == ''
            return [0, 0, str2]

        minLen = Math.min(str1.length, str2.length)
        diffStart = 0
        for i in [0...minLen]
            diffStart = i
            if str1[diffStart] != str2[diffStart]
                break

        # count the offset from the right side, subract diffStart to avoid
        # comparing against already visited indexes
        for j in [0...minLen - diffStart]
            diffEndOffset = j
            if str1[str1.length - j - 1] != str2[str2.length - j - 1]
                break

        if diffStart == 0 and diffEndOffset == 0
            return [0, str1.length, str2]
        else if diffStart == str1.length - 1 and str1.length < str2.length
            return [diffStart + 1, 0, str2[diffStart + 1..]]

        if diffStart <= str2.length - diffEndOffset - 1
            end = str2.length - diffEndOffset
            diffReplaced = (str1.length - diffEndOffset) - diffStart
            diffStr = str2[diffStart...end]
        else
            diffStr = ''
            diffReplaced = str1.length - str2.length

        diffReplaced = 0 if diffReplaced < 0

        [diffStart, diffReplaced, diffStr]

    stringDiffReversible = (str1, str2) ->
        [start, count, inserted] = stringDiff(str1, str2)
        removed = if count > 0 then str1[start...start + count] else ''
        [start, removed, inserted]

    stringSplice = (str, index, count, text) ->
            if text or count > 0
                str1 =  if index > 0 then str[...index] else ''
                "#{str1}#{text or ''}#{str[index + count..]}"
            else
                str


    module.exports =
        stringDiff: stringDiff
        stringSplice: stringSplice
        stringDiffReversible: stringDiffReversible
