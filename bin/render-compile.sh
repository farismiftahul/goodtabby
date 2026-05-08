#!/usr/bin/env bash
# Render build script for Tabbycat
# This script runs during Render's build step.
# Reference: https://render.com/docs/deploy-django

set -o errexit

echo "-----> Installing Python dependencies"
python -m pip install --upgrade pip
python -m pip install pipenv
pipenv install --system --deploy

echo "-----> Installing Node.js dependencies"
npm ci

echo "-----> Building frontend assets (Vite + Sass)"
npm run build

echo "-----> Entering tabbycat directory"
cd ./tabbycat/

echo "-----> Running database migrations"
python manage.py migrate --noinput

echo "-----> Running dynamic preferences checks"
python manage.py checkpreferences

echo "-----> Collecting static files"
python manage.py collectstatic --noinput -v 0

echo "-----> Build complete!"
