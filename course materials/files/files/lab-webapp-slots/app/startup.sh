#!/bin/bash
echo "Starting application..."
gunicorn --bind=0.0.0.0:8000 --workers=2 --timeout=600 app:app
