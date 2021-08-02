angular.module('lgLessons').service 'Syllabuses', (
    $http
    baseApiUrl
) ->

    class SyllabusesTree
        constructor: (syllabuses) ->
            @byId = {}
            @roots = []

            for syllabus in syllabuses
                @byId[syllabus.id] = syllabus
                syllabus.children = []

            for syllabus in syllabuses
                parent = syllabus.parent = @byId[syllabus.parent_id]
                if parent?
                    parent.children.push(syllabus)
                else
                    @roots.push(syllabus)

        getPathForId: (syllabusId) ->
            syllabus = @byId[syllabusId]
            path = []
            node = syllabus
            while node?
                path.unshift(node)
                node = node.parent
            path


    syllabusesCache = null


    @get = (reloadCache) ->
        if not reloadCache and syllabusesCache?
            return syllabusesCache

        syllabusesCache = $http
            .get "#{baseApiUrl}syllabuses/", params: {page_size: 999}
            .then (response) ->
                new SyllabusesTree(response.data.results)

    return this
