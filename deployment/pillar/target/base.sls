- tags:
    ? base
    ? s3

- django:
    s3:
        componentsBucket: '<undefined>'
        mediaBucket: '<undefined>'
        oldLessonsBucket: 'languagegarden.10clouds.com-oldlessons'
    use_south: true
    settings: {{ project_name|lower }}.settings.{{ instance_name }}
    site:
        domain: {{ domain }}
        name: {{ domain }}
    extension_id: 'fkaljappfngjammcehdecmoelmnjgklb'
    settings_filename: {{ instance_name }}.py

- sqlite:
    database:
        filename: db.sqlite3

- postgres:
    database:
        host: 127.0.0.1
        name: {{ project_name }}_{{ instance_name }}
    user:
        name: {{ user|lower }}
        password: qwe123

- system:
    user:
        name: {{ user }}
        id_rsa: |
            -----BEGIN RSA PRIVATE KEY-----
            MIIEpAIBAAKCAQEArlhH+YBq4TjHKUsizxJLMb9XevZOca57zDpT7bGrIcyBNCLe
            wPaWrgzoPGxnrsvo5C138bseQNzCmeMH+Hhi8VQ7CsEbmvV18bv8zct+XaVDuIR8
            BICCO6R/hnaqmp5A3gRazdx/xPxBL2rggM3L7albgI9fWJkxftFWygiP2zqonMDb
            zBSew+uYuzuIafB/3dRc3J8tc4edPcu6o8rlNY7K0r9hds6G0Blr4TYDeduy+0Py
            agXAcKdCVfNYHhgOtY+t4Vk3LzyUSWd0Grz5n4YM6xmnDYGM+/2+PH+dTrIYL9r8
            S7bGWtwPiCbZ+IOhYCaRWMgRZ1e0uGOGETSX8QIDAQABAoIBAQCJV+p7Vvrbqgrb
            MOGfFt49tmqH53ksfTPxUxHC8m/KFHzEQaQRhzB0tJ5O22digChbeKZAvBO9LSvw
            ZrVkvBHV43EPq8i/bhcX8+vXgzNtOj/7IANC2Km/qnr7xofnfjvDqtKN0eKln8MK
            Q7vQPE8mToBS6p9GAIjJSsiAJ/aL0IC781WpQCAbMhhhu//YvsibxbV7eMJ40zls
            dNRMWWppMGvc8OPzjQBc7Ne+phOFb0sb4hzYbkYs5mw9g4aqh1lqZqJt05wAHpTv
            pXR7j3bvkyuhIOebG92D7W4Gb7VHbT/32FmMOti2SfPq5ex8ptKJXqKbvDBKSZiN
            09uB/vExAoGBAN3BAe1KF5bum/pU4x7Lseyk0efkR6PBiR0fU8YlFQGbwSll9suU
            gcXjAh0aOe5jXVdb3bUcwK9I9n99nckQQNm/gQYT2/FPQmTCUfkH3HIM4wVyQmSg
            a0+6Mwo2NZ5mzR6vhaRjfkZdeuJCfcWpqb1Zk8Rn/rMt2Xdpy2v0Rlr/AoGBAMlE
            90XLkH27KJtixfgGJIvAmsHrwYWuUP/ke2cIF++HL0n4HXObuZqoCs8RQTawff+J
            W4Z/S8cjTdy1i9MEA0JH89DRSZNyo2z2hTnaln74MoODfTp4+F2qx4o2+TFPDzRi
            NCJP7oiXmNw+xNSWedFhbZd5xH0dLiywVcUTGb0PAoGBAIHR/23KZXr/36Ky1W/u
            8g/HAffO5b3RjJLXBzVF+kFBzNiOj+fo3fxahJ9C/k04MKn25xmjZo53mY9Tm+7c
            rAqOGVvUfnuL2iOgu1qeJolCUBmdJY9BdvFq4XyF9efw6P6g5Q0zDfblvQ3+vSDd
            zbhDW8Ws2ChPnDNTZTqi/BlDAoGAYRea7ZmAz5Z8xVDFzZsxABXe0hOn3JQ10Ovo
            t9BIs60UG+vMUVvbEodkB3X8bqR/c8lQVLaN2LfoNMODez0hUVUigiakBrQzsDnQ
            FROkrAWRYK4KuC1pKs5aygsw9R99ZzjEi5ThrhTrkbvZ+e/JPj9wvbTpG636+2Xp
            SlOng/MCgYBpmKLeI7woW1nvLjddoQSHn2Fk1vszLCdrWgsY7b5Vd/FjDebVHf4J
            Ui/OJ/vZHXgYN7NEk3QLxYJ5Aapm0RAZQ9wJ3/Pex0dnx/uLVTsFo+jnkVTRld44
            EfZm9+ITXVqDgWRI1ZAcV+NTsLGOg93v5G1G5oWy/Z8izO1ztrfspw==
            -----END RSA PRIVATE KEY-----
    packages:
        ? curl
        ? wget
        ? gettext
        ? libpq-dev
        ? python-dev
        ? libyaml-dev
        ? libjpeg-dev

        ? postgresql-client

    brew_packages:
        ? findutils
        ? jpeg
        ? wget
        ? gettext
        ? libpq
        ? libyaml
        ? curl

- venv:
    node:
        packages:
            ? "coffee-script@1.9.3"
            ? less@1.7.1
            ? bower@1.4.1
            ? grunt-cli@0.1.13
            ? yo@1.1.2
            ? generator-angular@0.7.1
            ? protractor@1.3.1
            ? webpack@1.4.13
            ? mocha@2.0.1

    python:
        packages:
            # Direct dependencies.
            ? Django>=1.7.1,<1.8.0
            ? djangorestframework>=3.0.2,<3.1.0
            ? "django-extensions>=1.3,<1.4"
            ? ipython>=2.1,<2.2
            ? unipath==1.0
            ? requests==2.2.1
            ? django-filter==0.7
            ? django-timedeltafield==0.7.1
            ? jsonfield<2.0.0
            ? django-haystack==2.3.1
            ? Whoosh==2.6.0
            ? django-mptt==0.6.1
            ? django-cors-headers==0.12
            ? boto>=2.30,<2.31
            ? django-rest-swagger>=0.2,<0.3
            ? django-smtp-ssl>=1.0,<2.0
            ? pytz==2014.4
            ? pillow==2.6.0
            ? progress==1.2
            ? dateutils>=0.6.6,<0.7.0
            ? xlrd==1.0.0
            ? XlsxWriter==0.9.6

            # For Memcached support.
            ? python-memcached==1.54

            # For PostgreSQL suppport.
            ? psycopg2-binary==2.7.3.2

            # For testing
            ? coverage==3.7.1
            ? mock==1.0.1
            ? factory_boy==2.3.1
            ? django-jenkins>=0.16.0,<0.17.0
            ? django-coverage>=1.2.0,<1.3.0
            ? django-tastypie==0.12.1
            ? selenium==2.40

- project:
    name: {{project_name}}
    instance: {{instance_name}}
    url: git@github.com:10clouds/languagegarden-web.git
    rev: master

    # Used to update SSH known hosts.
    host: github.com # The host used in url.
    host_fingerprint: 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48

{% set install_path = '/home/' + user + '/' + project_name %}
    install_path: {{ install_path }}
    backend_path: {{ install_path }}/repo/backend
    frontend_path: {{ install_path }}/repo/frontend
    components_path: {{ install_path }}/repo/components
