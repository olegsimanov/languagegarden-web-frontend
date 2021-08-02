    'use strict'

    {ClickBehavior} = require('./../../common/letterbehaviors/base')
    {EditorMode} = require('./../constants')


    class ModeSwitchAndSelectBehavior extends ClickBehavior

        storeMetric: =>
            # disabling metric logging
            # I don't think we should log this one at all

        onClick: (view, event, {letter}) =>
            super
            if @parentView.multiSelect
                view.select(not view.isSelected())
            else
                numOfSelected = @parentView.getSelectedViews().length
                if (numOfSelected == 1 and view.isSelected())
                    @parentView.deselectAll()
                else
                    @parentView.deselectAll(silent: true)
                    view.select(true)


    module.exports =
        ModeSwitchAndSelectBehavior: ModeSwitchAndSelectBehavior
