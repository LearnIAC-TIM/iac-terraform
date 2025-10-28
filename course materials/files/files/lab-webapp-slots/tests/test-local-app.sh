#!/bin/bash
# Test Flask app lokalt før deployment

set -e

echo "🧪 Testing Flask app locally..."

# Start appen i bakgrunnen
cd app
export ENVIRONMENT=test
export FEATURE_TOGGLE_X=true
python app.py &
APP_PID=$!
cd ..

# Vent på at appen starter
sleep 3

# Test endpoints
echo "→ Testing / endpoint..."
curl -s http://localhost:8000/ | jq .

echo "→ Testing /health endpoint..."
curl -s http://localhost:8000/health | jq .

echo "→ Testing /feature-x endpoint..."
curl -s http://localhost:8000/feature-x | jq .

# Stopp appen
kill $APP_PID

echo "✅ Local tests passed!"
