require('../polyfills/console')
{PlantController} = require('./editor/controllers')

load = () ->

    controller = new PlantController(document.body)
    controller.start()

    return

Starter = {}
Starter.load = load

window.PlantStarter = Starter
