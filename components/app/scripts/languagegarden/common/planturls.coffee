    'use strict'

    urlPattern = /^languagegarden:\/\/plant\/([0-9]+)(\/(\?groovy=1)?)?$/

    getRedirectInfoFromUrl = (plantUrl) ->
        m = urlPattern.exec(plantUrl or '')
        redirectInfo = null
        if m?
            redirectInfo =
                plantId: m[1]
            if m[3]?
                redirectInfo.groovy = true
        redirectInfo


    module.exports =
        urlPattern: urlPattern
        getRedirectInfoFromUrl: getRedirectInfoFromUrl
