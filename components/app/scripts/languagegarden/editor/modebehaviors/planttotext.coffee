    'use strict'

    _ = require('underscore')
    MediumSelectBehavior = require('./../mediabehaviors/select').SelectBehavior
    MediumMoveBehavior = require('./../mediabehaviors/move').MoveBehavior
    MediumEditBehavior = require('./../mediabehaviors/edit').EditBehavior
    {PlantToTextBehavior} = require('./../../common/modebehaviors/planttotext')


    class EditorPlantToTextBehavior extends PlantToTextBehavior
        mediaClasses: [
            MediumSelectBehavior,
            MediumMoveBehavior,
            MediumEditBehavior,
        ]


    module.exports =
        PlantToTextBehavior: EditorPlantToTextBehavior
