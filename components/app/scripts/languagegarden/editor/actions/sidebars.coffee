    'use strict'

    _ = require('underscore')
    {GoToSidebarChapter} = require('./../../common/actions/sidebars')


    class EditorGoToSidebarChapter extends GoToSidebarChapter
        id: 'go-to-sidebar-chapter'


        perform: ->
            super
            @controller.setToolbarState(null)


    class GoToTitlePage extends EditorGoToSidebarChapter

        id: 'go-to-title-page'

        initialize: (options) ->
            options = _.clone(options)
            options.chapterIndex = 0
            super(options)


    module.exports =
        GoToSidebarChapter: EditorGoToSidebarChapter
        GoToTitlePage: GoToTitlePage
