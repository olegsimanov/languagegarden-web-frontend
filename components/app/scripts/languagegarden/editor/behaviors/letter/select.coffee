    'use strict'

    {ClickBehavior}     = require('./base')
    {EditorMode}        = require('./../../constants')


    class ModeSwitchAndSelectBehavior extends ClickBehavior

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
