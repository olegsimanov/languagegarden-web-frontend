    'use strict'

    _ = require('underscore')

    {ButtonGroup}               = require('./../../../editor/views/buttongroups/base')
    {
        SplitSentenceElement,
        SplitWordElement
    }                           = require('./../../actions/split')
    {DeleteAction}              = require('./../../actions/delete')
    {
        SwitchToRotate
        SwitchToStretch
        SwitchToGroupScale
        SwitchToScale
        SwitchToMove
    }                           = require('./../../actions/modeswitch')
    {StartUpdating}             = require('./../../actions/edit')
    StartUpdatingText           = require('./../../actions/edittext').StartUpdating


    class SelectionButtonGroup extends ButtonGroup

        className: "#{ButtonGroup::className} buttons-group_selection"

        actionSpec: [
            id:             'switch-to-rotate'
            actionClass:    SwitchToRotate
            className:      'tooltip-switch-to-rotate icon icon_refresh'
            help:           'Switch to rotate'
        ,
            id:             'switch-to-scale'
            actionClass:    SwitchToScale
            className:      'tooltip-switch-to-scale icon icon_scale'
            help:           'Switch to scale'
        ,
            id:             'switch-to-group-scale'
            actionClass:    SwitchToGroupScale
            className:      'tooltip-switch-to-scale icon icon_scale'
            help:           'Switch to scale'
        ,
            id:             'switch-to-move'
            actionClass:    SwitchToMove
            className:      'tooltip-switch-to-move icon icon_move'
            help:           'Switch to move'
        ,
            id:             'switch-to-stretch'
            actionClass:    SwitchToStretch
            className:      'tooltip-switch-to-stretch icon icon_stretch'
            help:           'Switch to stretch'
        ,
            id:             'wordsplit'
            actionClass:    SplitWordElement
            className:      'tooltip-word-split icon icon_scissors'
            help:           'Split word at cursor'
        ,
            id:             'edit'
            actionClass:    StartUpdating
            className:      'tooltip-edit icon icon_pencil'
            help:           'Edit'
        ,
            id:             'edittext'
            actionClass:    StartUpdatingText
            className:      'tooltip-edit'
            help:           'Edit'
        ,
            id:             'delete'
            actionClass:    DeleteAction
            className:      'tooltip-bin icon icon_trash'
            help:           'Delete selected'
        ]


    module.exports =
        SelectionButtonGroup: SelectionButtonGroup
