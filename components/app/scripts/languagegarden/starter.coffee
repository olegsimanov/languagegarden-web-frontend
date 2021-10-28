require('../polyfills/console')
{PlantController} = require('./editor/controllers')
{CanvasView} = require('./editor/views/canvas')

load = () ->

    controller = new PlantController(document.body)
    controller.start()

    return

test1 = () ->

    controller = new CanvasView({

    })
    controller.render()

    return


Starter = {}
Starter.load = load

PlantTester = {}
PlantTester.test = test1

window.PlantStarter = Starter
window.PlantTester  = PlantTester
