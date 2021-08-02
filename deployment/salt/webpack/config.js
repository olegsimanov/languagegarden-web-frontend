(function () {
    'use strict';

    var path = require('path');
    var publicPath = '';
    var bucket = null;
    var sentryPublicDSN = null;

{% if 's3' in pillar.tags and not pillar.django.debug %}
    bucket = '{{ pillar.django.s3.componentsBucket }}';
    publicPath = 'https://s3.amazonaws.com/' + bucket + '/';
{%- else %}
    publicPath = '/static/';
{% endif %}
{% if 'sentry' in pillar.tags %}
    sentryPublicDSN = '{{ pillar.django.sentry.public_dsn }}';
{%- endif %}
    module.exports = {
        output: {
            publicPath: publicPath
        },
        s3: {
            componentsBucket: bucket
        },
        sentry: {
            publicDSN: sentryPublicDSN
        }
    };
}).call(this);
