from .base import *

{% if 'postgres' in pillar.tags -%}
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'HOST': '{{ pillar.postgres.database.host }}',
        'NAME': '{{ pillar.postgres.database.name }}',
        'USER': '{{ pillar.postgres.user.name }}',
        'PASSWORD': '{{ pillar.postgres.user.password }}',
        'ATOMIC_REQUESTS': True,
    }
}
{%- endif %}

{% if 'sqlite' in pillar.tags -%}
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, '{{ pillar.sqlite.database.filename }}'),
    }
}
{%- endif %}

DEBUG = {{ pillar.django.debug }}
TEMPLATE_DEBUG = DEBUG

{% if not pillar.django.debug -%}
STATIC_ROOT = '{{ pillar.project.install_path }}/var/static'
ALLOWED_HOSTS = ['{{ pillar.django.site.domain }}']
{%- else -%}
STATIC_ROOT = os.path.join(BASE_DIR, 'collected_static')
STATICFILES_DIRS = (
    os.path.join(BASE_DIR, '..', 'components', 'build'),
)
{%- endif %}

# for mixed http/https requests (see django-rest-swagger)
CORS_ORIGIN_WHITELIST = (
    '{{ pillar.django.site.domain }}',
)

{% if 'jenkins' in pillar.tags -%}
INSTALLED_APPS += ('django_jenkins',)

JENKINS_TASKS = (
    'django_jenkins.tasks.run_pyflakes',
    'django_jenkins.tasks.run_pep8',
    'django_jenkins.tasks.with_coverage',
)
{%- endif %}

{% if 's3' in pillar.tags -%}
{% if not pillar.django.debug -%}
LG_COMPONENTS_S3_BUCKET = '{{ pillar.django.s3.componentsBucket }}'
LG_COMPONENTS_BASE_URL = S3_BUCKET_URL_TEMPLATE.format(
    bucket=LG_COMPONENTS_S3_BUCKET)
{%- endif %}


LG_MEDIA_S3_BUCKET = '{{ pillar.django.s3.mediaBucket }}'
LG_MEDIA_BASE_URL = S3_BUCKET_URL_TEMPLATE.format(bucket=LG_MEDIA_S3_BUCKET)

LG_OLD_LESSONS_S3_BUCKET = '{{ pillar.django.s3.oldLessonsBucket }}'
LG_OLD_LESSONS_BASE_URL = pjoin(
    S3_BUCKET_URL_TEMPLATE.format(bucket=LG_OLD_LESSONS_S3_BUCKET),
    'Content',
)
{%- endif %}

{% if pillar.django.debug -%}
LG_COMPONENTS_BASE_URL = '/static/'
{%- endif %}

{% if 'sentry' in pillar.tags -%}
INSTALLED_APPS += ('raven.contrib.django.raven_compat', )

RAVEN_CONFIG = {
    'dsn': '{{ pillar.django.sentry.dsn }}',
}

LOGGING['handlers'].update({
    'sentry_warning': {
        'level': 'WARNING',
        'class': 'raven.contrib.django.raven_compat.handlers.SentryHandler',
    },
    'verbose_console': {
        'level': 'WARNING',
        'class': 'logging.StreamHandler',
        'formatter': 'verbose',
    },
})

LOGGING['root']['handlers'].append('sentry_warning')

# Append `sentry_warning` handler to all loggers that do not propagate.
for logger in LOGGING['loggers'].itervalues():
    if logger.get('propagate', False):
        continue

    if 'sentry_warning' in logger.get('handlers', []):
        continue

    logger.setdefault('handlers', []).append('sentry_warning')

LOGGING['loggers'].update({
    'raven': {
        'level': 'DEBUG',
        'handlers': ['verbose_console'],
        'propagate': False,
    },
    'sentry.errors': {
        'level': 'DEBUG',
        'handlers': ['verbose_console'],
        'propagate': False,
    },
})
{%- endif %}

{% if 'console' in pillar.tags -%}
LOGGING['handlers']['console'] = {
    'level': 'DEBUG',
    'class': 'logging.StreamHandler',
    'formatter': 'simple'
}

LOGGING['root']['handlers'].append('console')
LOGGING['root']['level'] = 'INFO'

LOGGING['loggers']['django.request']['handlers'].append('console')
{%- endif %}
{% if 'email_backend' in pillar.tags -%}
EMAIL_BACKEND = '{{ pillar.django.email.backend }}'
{%- endif%}
{% if 'email_credentials' in pillar.tags -%}
EMAIL_HOST = '{{ pillar.django.email.host }}'
EMAIL_PORT = '{{ pillar.django.email.port }}'
EMAIL_HOST_USER = '{{ pillar.django.email.user }}'
EMAIL_HOST_PASSWORD = '{{ pillar.django.email.password }}'
{%- endif%}

EXTENSION_ID = '{{ pillar.django.extension_id }}'

{% if 'memcached' in pillar.tags -%}
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
    }
}
{%- endif %}

local_settings = os.path.join(os.path.dirname(__file__), 'local.py')
if os.path.isfile(local_settings):
    from .local import *
