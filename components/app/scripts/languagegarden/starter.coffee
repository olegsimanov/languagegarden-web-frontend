require('../polyfills/console')
{PlantEditorController} = require('./editor/controllers')

load = () ->

    controller = new PlantEditorController
    controller.start()

    return

Starter = {}
Starter.load = load

window.PlantStarter = Starter
