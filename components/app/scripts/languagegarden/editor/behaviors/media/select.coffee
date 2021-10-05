    'use strict'

    {ClickBehavior} = require('./base')



    class SelectBehavior extends ClickBehavior

        onClick: (view, event) =>
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
        SelectBehavior: SelectBehavior
