#!/bin/bash
set -euo pipefail

# Bootstrap a Python Flask API served by gunicorn on Amazon Linux 2023.
# DB credentials are pulled at boot from Secrets Manager via the instance
# role; they are never baked into the AMI or this script.

dnf update -y
dnf install -y python3 python3-pip jq awscli

APP_DIR=/opt/app
mkdir -p "$${APP_DIR}"

pip3 install --no-cache-dir flask gunicorn psycopg2-binary boto3

# Fetch DB connection info from Secrets Manager.
SECRET_JSON="$(aws secretsmanager get-secret-value \
  --region "${aws_region}" \
  --secret-id "${db_secret_arn}" \
  --query SecretString --output text)"

DB_HOST="$(echo "$${SECRET_JSON}" | jq -r .host)"
DB_PORT="$(echo "$${SECRET_JSON}" | jq -r .port)"
DB_NAME="$(echo "$${SECRET_JSON}" | jq -r .dbname)"
DB_USER="$(echo "$${SECRET_JSON}" | jq -r .username)"
DB_PASS="$(echo "$${SECRET_JSON}" | jq -r .password)"

# Minimal placeholder Flask app with a /health endpoint for the ALB.
# Replace app.py with your real application via your deploy pipeline.
cat > "$${APP_DIR}/app.py" <<'PYEOF'
import os
from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/health")
def health():
    return jsonify(status="ok"), 200


@app.route("/")
def index():
    return jsonify(message="Flask API is running"), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("APP_PORT", "8000")))
PYEOF

cat > /etc/app.env <<ENVEOF
APP_PORT=${app_port}
DB_HOST=$${DB_HOST}
DB_PORT=$${DB_PORT}
DB_NAME=$${DB_NAME}
DB_USER=$${DB_USER}
DB_PASSWORD=$${DB_PASS}
ENVEOF
chmod 600 /etc/app.env

cat > /etc/systemd/system/flaskapp.service <<UNITEOF
[Unit]
Description=Flask API
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=/etc/app.env
WorkingDirectory=$${APP_DIR}
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 0.0.0.0:${app_port} app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNITEOF

systemctl daemon-reload
systemctl enable --now flaskapp.service
