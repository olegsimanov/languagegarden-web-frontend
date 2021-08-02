#!jinja|yaml|merge
{% set project_name = 'languagegarden' %}
{% set instance_name = 'test' %}
{% set user = 'languagegarden-test' %}
{% set domain = 'languagegarden.10clouds.com' %}

{% include 'target/base.sls' %}

- tags:
    ? sqlite
    ? jenkins

- django:
    debug: false
    jenkins:
        pep8:
            ignore: []
            exclude: []

- venv:
    python:
        packages:
            ? mock==1.0.1
            ? factory_boy==2.3.1
            ? flake8>=2.1.0,<2.2.0
            ? pyflakes==0.8.1

- project:
    rev: master
