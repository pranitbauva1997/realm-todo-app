import os
import dj_database_url
import pygments.formatters

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

INSTALLED_APPS = ["hello", "django_extensions"]

DATABASES = {"default": dj_database_url.config()}

ROOT_URLCONF = "proj.urls"
SECRET_KEY = "lkjwerlkwjerlkjwelkjrwelkjrwlekjrlwkejrwelrkjlkjsdflkj"
WSGI_APPLICATION = "proj.wsgi.application"

DEBUG = True
ALLOWED_HOSTS = []
MIDDLEWARE = []
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_L10N = True
USE_TZ = True

SHELL_PLUS_PRINT_SQL = True
SHELL_PLUS_PRINT_SQL_TRUNCATE = 1000
SHELL_PLUS_SQLPARSE_FORMAT_KWARGS = dict(reindent_aligned=True, truncate_strings=500)
SHELL_PLUS_PYGMENTS_FORMATTER = pygments.formatters.TerminalFormatter
SHELL_PLUS_PYGMENTS_FORMATTER_KWARGS = {}
