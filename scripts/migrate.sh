#!/usr/bin/env bash

set -e
cd dj
DATABASE_URL=${DATABASE_URL_PY} ../venv/bin/python manage.py migrate
