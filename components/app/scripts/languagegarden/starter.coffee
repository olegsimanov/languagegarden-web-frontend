require('../polyfills/console')
{PlantEditorController} = require('./editor/controllers')

load = (containerElement, options={}) ->

    controller = new PlantEditorController
    controller.start()

    return

Starter = {}
Starter.load = load

window.PlantStarter = Starter
