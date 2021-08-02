'use strict'

_ = require('underscore')
{applyDiff} = require('./diffs/utils')
{deepCopy} = require('./utils')


findAllMediaUrlsHelper = (initialSnapshot, diffs) ->
    snapshot = deepCopy(initialSnapshot)
    mediaUrlsDict = {}

    collectUrls = ->
        mediaSnapshots = snapshot?.media or []
        for mediumSnapshot in mediaSnapshots
            if mediumSnapshot.url?
                mediaUrlsDict[mediumSnapshot.url] = 1

    collectUrls()

    for diff in diffs
        snapshot = applyDiff(snapshot, diff)
        collectUrls()

    _.keys(mediaUrlsDict)


preloadImageUrl = (url) ->
    img = new Image()
    img.src = url
    img


# we don't preload sounds - they can be loaded on-demand
preloadSoundUrl = (url) ->


preloadUrl = (url) ->
    imageRegExp = /^.+\.(jpg|jpeg|png|gif)$/
    soundRegExp = /^.+\.(mp3)$/

    if imageRegExp.test(url)
        return preloadImageUrl(url)
    if soundRegExp.test(url)
        return preloadSoundUrl(url)

    console.warn("#{url} not supported in preloadUrl")


preloadUrls = (urls) ->
    for url in urls
        preloadUrl(url)
    return


preloadMediaFromDataModel = (dataModel) ->
    snapshot = dataModel.initialState.toJSON()
    diffs = dataModel.getDiffs()
    urls = findAllMediaUrlsHelper(snapshot, diffs)
    preloadUrls(urls)


module.exports =
    preloadMediaFromDataModel: preloadMediaFromDataModel
