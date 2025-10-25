from flask import Flask, jsonify
import os
import json

app = Flask(__name__)

# Load config from env
app_name = os.getenv("APP_NAME", "demo-app")
env = os.getenv("ENV", "unknown")
debug = os.getenv("DEBUG", "false")
api_key = os.getenv("API_KEY", "not-set")

@app.route("/")
def home():
    return jsonify({
        "app_name": app_name,
        "environment": env,
        "debug": debug,
        "api_key_snippet": api_key[:5] + "..."  # don’t print full secret
    })

@app.route("/health")
def health():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
