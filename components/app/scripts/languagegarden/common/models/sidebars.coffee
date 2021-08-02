    'use strict'

    {BaseModel, BaseCollection, BaseModelWithSubCollections} = require('./base')


    class ChapterElement extends BaseModel

        getActiveElementIndex: ->
            @collection.getParentModel().getActiveElementIndex()

        getElementIndex: ->
            if (index = @collection.indexOf(this)) >= 0 then index else null

        isActive: -> @collection.at(@getActiveElementIndex()) == this


    class ChapterElements extends BaseCollection
        model: ChapterElement


    class Chapter extends BaseModelWithSubCollections

        subCollectionConfig: [
            name: 'elements'
            collectionClass: ChapterElements
        ]

        initialize: (options) ->
            @setDefaultValue('activeElementIndex', null)

        getActiveChapterIndex: ->
            @collection.getParentModel().getActiveChapterIndex()

        getChapterIndex: ->
            if (index = @collection.indexOf(this)) >= 0 then index else null

        isActive: -> @collection.at(@getActiveChapterIndex()) == this

        getActiveElementIndex: -> @get('activeElementIndex')

        getActiveElement: -> @elements.at(@getActiveElementIndex())

        activateElementByIndex: (index, options) ->
            oldActiveElement = @getActiveElement()
            result = @set('activeElementIndex', index, options)
            newActiveElement = @getActiveElement()
            if not options?.silent and newActiveElement != oldActiveElement
                oldActiveElement?.trigger('activate', this, false)
                newActiveElement?.trigger('activate', this, true)
            result

    class Chapters extends BaseCollection
        model: Chapter


    class SidebarState extends BaseModelWithSubCollections

        subCollectionConfig: [
            name: 'chapters'
            collectionClass: Chapters
        ]

        initialize: (options) ->
            @setDefaultValue('placeholder', false)
            @setDefaultValue('plantId', null)
            @setDefaultValue('titlePageImageUrl', null)
            @setDefaultValue('activeChapterIndex', 0)
            @setDefaultValue('scrollOffset', 0)
            @setupEventForwarding(@chapters, 'change:activeElementIndex')

        getChapters: -> @chapters

        getActiveChapterIndex: -> @get('activeChapterIndex')

        getActiveChapter: -> @chapters.at(@getActiveChapterIndex())

        getActiveActivityId: ->
            activeElement = @getActiveChapter().getActiveElement()
            activeElement.get('activityId')

        getNextChapterWithActivities: (chapter) ->
            nextChapter = @getChapters().at(chapter.getChapterIndex() + 1)
            if nextChapter
                if nextChapter.elements.length
                    return nextChapter
                else
                    return @getNextChapterWithActivities(nextChapter)
            else
                return null

        getElementAfterActiveElement: ->
            activeChapter = @getActiveChapter()
            activeElement = activeChapter.getActiveElement()

            if (not activeElement? or
                    activeElement is activeChapter.elements.last())
                nextChapter = @getNextChapterWithActivities(activeChapter)
                if nextChapter
                    return nextChapter.elements.first()
                else
                    return null
            else
                activeElementIndex = activeElement.getElementIndex()
                return activeChapter.elements.at(activeElementIndex + 1)

        getElementsIds: ->
            ids = []
            for chapter in @getChapters().models
                for element in chapter.elements.models
                    ids.push(element.get('activityId'))
            ids

        activateChapterByIndex: (index, elementIndex=null, options) ->
            oldIndex = @getActiveChapterIndex()
            oldActiveChapter = @getActiveChapter()
            newActiveChapter = @chapters.at(index)

            if oldIndex != index
                oldActiveChapter?.activateElementByIndex(null, options)
            newActiveChapter?.activateElementByIndex(elementIndex, options)
            @set('activeChapterIndex', index, options)

        activateElementByActivityId: (activityId, options) ->
            chapterIndex = null
            elementIndex = null
            for chapter in @chapters.models
                for element in chapter.elements.models
                    if element.get('activityId') == activityId
                        chapterIndex = chapter.getChapterIndex()
                        elementIndex = element.getElementIndex()
            if chapterIndex? and elementIndex?
                @activateChapterByIndex(chapterIndex, elementIndex, options)
            return


    module.exports =
        SidebarState: SidebarState
