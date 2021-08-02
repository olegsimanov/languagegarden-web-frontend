#!jinja|yaml|merge
{% set project_name = 'languagegarden' %}
{% set instance_name = 'production' %}
{% set user = 'languagegarden' %}
{% set domain = 'app.languagegarden.com' %}

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
        user: 'AKIAIRDAKFVYH665MK2A'
        password: '<INSERT_IN_LOCAL>'
    s3:
        componentsBucket: 'app.languagegarden.com-components'
        mediaBucket: 'app.languagegarden.com-media'
        oldLessonsBucket: 'app.languagegarden.com-oldlessons'
    extension_id: 'aamdbafophajiecmhbnbakndfgjkfpce'
    runfcgi:
        nginx:
            vhost: {{ domain }}
        port: 8002
    sentry:
        dsn: 'http://416dedd984c54fe1b4718e9e80cb864e:b9b9ffda307a4776acfbb6ce7ce5ed55@sentry.10clouds.com/51'
        public_dsn: 'http://416dedd984c54fe1b4718e9e80cb864e@sentry.10clouds.com/51'

- system:
    packages:
        ? memcached

- postgres:
    database:
        host: lg-production.cup5fcjnkkjd.us-east-1.rds.amazonaws.com
    user:
        password: Tipjushansh9

- project:
    rev: stable
