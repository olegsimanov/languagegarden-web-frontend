#!jinja|yaml|merge
{% set project_name = 'languagegarden' %}
{% set instance_name = 'localhost' %}
{% set user = 'languagegarden' %}
{% set domain = 'localhost' %}

{% include 'target/base.sls' %}

- tags:
    ? sqlite
    ? console
    ? email_backend

- django:
    debug: true
    email:
        backend: 'django.core.mail.backends.console.EmailBackend'
    s3:
        mediaBucket: 'languagegarden.local-media'

- project:
    rev: master
