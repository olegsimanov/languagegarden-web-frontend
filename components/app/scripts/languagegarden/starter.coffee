require('../polyfills/console')
require('../ravenconfig')
require('../../styles/loader.less')
{configure} = require('./config')

loader =  (element, options={}) ->

    useHashes = options.useHashes
    useHashes ?= false
    useURL = options.useURL
    useURL ?= true
    rootURL = options.rootURL or '/'

    element ?= document.body
    loaderElement = document.createElement('div')
    loaderElement.className = 'loader'
    element.appendChild(loaderElement)

    routerOptions = {}
    for key of options
        routerOptions[key] = options[key]

    routerOptions.containerElement ?= element
    routerOptions.loaderElement ?= loaderElement
    routerOptions.useURL ?= useURL

    navInfo =
        type: options.type
        plantId: options.plantId

    {Router} = require('./router/base')
    Backbone = require('backbone')
    do ->
        router = new Router(routerOptions)

        if useURL
            Backbone.history.start
                pushState: useURL and not useHashes
                hashChange: useURL and useHashes
                root: rootURL
            if navInfo.type?
                router.navigateToController(navInfo)
        else
            router.navigateToController(navInfo)

root = window or global

module.exports = loader
root.languagegarden ?= {}
root.languagegarden.object = loader
root.languagegarden.configure = configure
