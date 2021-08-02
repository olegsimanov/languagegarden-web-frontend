    'use strict'

    settings = require('./../../settings')
    config = require('./../../config')
    {BaseModel} = require('./../../common/models/base')
    {PaginatedCollection} = require('./../../common/models/pagination')


    class MediumMeta extends BaseModel
        idAttribute: 'id'


    class MediumMetaCollection extends PaginatedCollection
        model: MediumMeta
        urlRoot: -> config.getUrlRoot(settings.apiResourceNames.blobs)
        filters:
            'confirmed': 'true'


    class SoundMediumMetaCollection extends MediumMetaCollection
        filters:
            'type': 'sound'
            'confirmed': 'true'


    class ImageMediumMetaCollection extends MediumMetaCollection
        filters:
            'type': 'image'
            'confirmed': 'true'


    module.exports =
        MediumMeta: MediumMeta
        SoundMediumMetaCollection: SoundMediumMetaCollection
        ImageMediumMetaCollection: ImageMediumMetaCollection
