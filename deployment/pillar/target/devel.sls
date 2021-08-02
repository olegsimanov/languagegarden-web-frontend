#!jinja|yaml|merge
{% set project_name = 'languagegarden' %}
{% set instance_name = 'devel' %}
{% set user = 'languagegarden' %}
{% set domain = 'languagegarden.10clouds.com' %}

{% include 'target/base.sls' %}

- tags:
    ? postgres
    ? sentry
    ? memcached
    ? email_backend
    ? email_credentials

- django:
    debug: false
    email:
        backend: 'django_smtp_ssl.SSLEmailBackend'
        host: 'email-smtp.us-east-1.amazonaws.com'
        port: 465
        user: 'AKIAICFE3TAVVATU7EUQ'
        password: '<INSERT_IN_LOCAL>'
    s3:
        componentsBucket: 'languagegarden.10clouds.com-components'
        mediaBucket: 'languagegarden.10clouds.com-media'
        oldLessonsBucket: 'languagegarden.10clouds.com-oldlessons'
    sentry:
        dsn: 'http://39a4eb1bedc44f8889b1d081c73d5968:a2ef2f20b35a4a3bb81b6f969846db1b@sentry.10clouds.com/50'
        public_dsn: 'http://39a4eb1bedc44f8889b1d081c73d5968@sentry.10clouds.com/50'
    runfcgi:
        nginx:
            user:
                name: 10clouds
                password: spinningcats
            vhost: {{ domain }}
        port: 8000

- system:
    packages:
        ? memcached

- project:
    rev: master
