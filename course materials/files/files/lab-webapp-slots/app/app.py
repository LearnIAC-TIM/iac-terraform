from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

# Hent miljøvariabler
ENVIRONMENT = os.getenv('ENVIRONMENT', 'unknown')
FEATURE_TOGGLE_X = os.getenv('FEATURE_TOGGLE_X', 'false').lower() == 'true'
VERSION = os.getenv('APP_VERSION', '1.0.0')

@app.route('/')
def home():
    """Hovedside med miljøinformasjon"""
    return jsonify({
        'message': 'Azure Web App Slots Lab',
        'environment': ENVIRONMENT,
        'version': VERSION,
        'hostname': socket.gethostname(),
        'feature_x_enabled': FEATURE_TOGGLE_X
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'environment': ENVIRONMENT,
        'checks': {
            'app': 'ok',
            'feature_toggle': FEATURE_TOGGLE_X
        }
    }), 200

@app.route('/feature-x')
def feature_x():
    """Feature toggle demo"""
    if FEATURE_TOGGLE_X:
        return jsonify({
            'feature': 'X',
            'enabled': True,
            'message': 'Dette er den nye funksjonen!',
            'environment': ENVIRONMENT
        })
    else:
        return jsonify({
            'feature': 'X',
            'enabled': False,
            'message': 'Feature X er ikke tilgjengelig ennå.',
            'environment': ENVIRONMENT
        })

@app.route('/api/version')
def version():
    """Versjonsinformasjon"""
    return jsonify({
        'version': VERSION,
        'environment': ENVIRONMENT,
        'deployment_slot': 'staging' if 'staging' in ENVIRONMENT.lower() else 'production'
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
