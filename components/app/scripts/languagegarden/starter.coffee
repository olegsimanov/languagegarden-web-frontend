require('../polyfills/console')
require('../ravenconfig')
require('../../styles/loader.less')
PlantConfig = require('./config')
{Router} = require('./router/base')

createLoaderElement = () =>
    loaderElement = document.createElement('div')
    loaderElement.className = 'loader'
    return loaderElement

createRouterOptions = (loaderElement, containerElement, options = {}) =>
    routerOptions = {}
    for key of options
        routerOptions[key] = options[key]

    routerOptions.containerElement  ?= containerElement
    routerOptions.loaderElement     ?= loaderElement
    return routerOptions

load = (containerElement, options={}) ->

    loaderElement = createLoaderElement();
    containerElement.appendChild(loaderElement)

    router = new Router(createRouterOptions(loaderElement, containerElement))
    router.navigateToController(
        type:       options.type
        plantId:    options.plantId
    )

Starter = {}
Starter.load = load

window.PlantConfig = PlantConfig
window.PlantStarter = Starter
