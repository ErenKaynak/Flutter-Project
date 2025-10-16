from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import json

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# LM Studio server URL (default port is 1234)
LM_STUDIO_URL = "http://localhost:1234"

@app.route('/v1/models', methods=['GET', 'OPTIONS'])
def get_models():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        response = requests.get(f"{LM_STUDIO_URL}/v1/models")
        return response.json(), response.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/v1/chat/completions', methods=['POST', 'OPTIONS'])
def chat_completions():
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.json
        response = requests.post(
            f"{LM_STUDIO_URL}/v1/chat/completions",
            json=data,
            headers={'Content-Type': 'application/json'}
        )
        return response.json(), response.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=1234) 