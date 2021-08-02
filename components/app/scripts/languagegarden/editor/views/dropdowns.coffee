_ = require('underscore')
{DropDown} = require('./../../common/views/dropdowns')
{DuplicateStationAndGoToCreator} = require('./../actions/navigation')

class DuplicateStationDropDown extends DropDown

    initialize: (options) ->
        super
        @setPropertyFromOptions(options, 'dataModel',
                                default: @controller.dataModel
                                required: true)
        @value ?= ''

    getRenderOptions: ->
        options = [
            name: 'Duplicate new Station'
            value: ''
        ]
        stationPositions = @dataModel.getAllStationPositions()
        for index in [0...stationPositions.length]
            options.push
                name: "Station #{index}"
                value: index
        options

    onSelectChange: ->
        super
        val = parseInt(@value, 10)
        if _.isNaN(val)
            return
        action = new DuplicateStationAndGoToCreator
            controller: @controller
            stationIndex: val
        action.fullPerform()
        action.remove()
        return


module.exports =
    DuplicateStationDropDown: DuplicateStationDropDown
