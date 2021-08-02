'use strict'

_ = require('underscore')
{ButtonGroup} = require('./../../../common/views/buttongroups/base')
plantToTextActions = require('./../../actions/plant_to_text')
{PunctuationButton} = require('./../../../common/views/buttons')


class PlantToTextButtonGroup extends ButtonGroup

    className: "#{ButtonGroup::className} buttons-group_plant-to-text buttons-group_plant-to-text_in-player"

    actionSpec: [
        id: 'plant-to-text-to-upper'
        actionClass: plantToTextActions.ToUpper
        className: 'tooltip-plant-to-text-to-upper icon icon_uppercase'
        help: 'Capitalize the last word'
    ,
        id: 'plant-to-text-to-lower'
        actionClass: plantToTextActions.ToLower
        className: 'tooltip-plant-to-text-to-lower icon icon_lowercase'
        help: 'Lowercase the last word'
    ,
        id: 'plant-to-text-remove'
        actionClass: plantToTextActions.Remove
        className: 'tooltip-plant-to-text-remove icon icon_erase'
        help: 'Remove last word'
    ,
        actionClass: plantToTextActions.AddComma
        className: 'tooltip-p2t-add-comma'
        viewClass: PunctuationButton
    ,
        actionClass: plantToTextActions.AddPeriod
        className: 'tooltip-p2t-add-period'
        viewClass: PunctuationButton
    ,
        actionClass: plantToTextActions.AddQuestionMark
        className: 'tooltip-p2t-add-question-mark'
        viewClass: PunctuationButton
    ,
        actionClass: plantToTextActions.AddSemicolon
        className: 'tooltip-p2t-add-semicolon'
        viewClass: PunctuationButton
    ,
        actionClass: plantToTextActions.AddColon
        className: 'tooltip-p2t-add-colon'
        viewClass: PunctuationButton
    ,
        actionClass: plantToTextActions.AddExclamationMark
        className: 'tooltip-p2t-add-exclamation-mark'
        viewClass: PunctuationButton
    ,
        actionClass: plantToTextActions.AddDash
        className: 'tooltip-p2t-add-dash'
        viewClass: PunctuationButton
    ,
        actionClass: plantToTextActions.AddQuotationMark
        className: 'tooltip-p2t-add-quotation-mark'
        viewClass: PunctuationButton
    ]


module.exports =
    PlantToTextButtonGroup: PlantToTextButtonGroup
