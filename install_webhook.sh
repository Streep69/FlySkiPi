#!/usr/bin/env bash
set -euo pipefail
LOG=/var/log/fortresspi_webhook.log
exec > >(tee -a "$LOG") 2>&1

echo "[*] Installing FortressPi Webhook Listener..."

apt-get update -qq
apt-get install -y python3 python3-pip
pip3 install flask

WEBHOOK_DIR="/opt/fortresspi_webhook"
mkdir -p "$WEBHOOK_DIR"

cat >"$WEBHOOK_DIR/app.py" <<'PY'
from flask import Flask, request
app = Flask(__name__)

@app.route("/webhook", methods=["POST"])
def webhook():
    print(f"Received: {request.json}")
    return {"status": "received"}, 200

app.run(host="0.0.0.0", port=9123)
PY

cat >/etc/systemd/system/fortresspi_webhook.service <<'UNIT'
[Unit]
Description=FortressPi Webhook Listener
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/fortresspi_webhook/app.py
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now fortresspi_webhook.service
ufw allow 9123

echo "[✔] Webhook listener installed at http://<ip>:9123/webhook"
